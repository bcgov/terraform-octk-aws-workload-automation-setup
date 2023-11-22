import json
import boto3
from datetime import datetime, timezone, timedelta
import logging
import time
import os


# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Set up AWS clients
iam_client = boto3.client('iam')
dynamodb_client = boto3.client('dynamodb')
ssm_client = boto3.client('ssm')

# DynamoDB Table Name
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')

def lambda_handler(event, context):
    try:
        # Check if the Lambda is triggered by DynamoDB Stream
        if 'Records' in event:
            for record in event['Records']:
                user_name = record['dynamodb']['Keys']['UserName']['S']
                if record['eventName'] in ['INSERT', 'MODIFY']:
                    logger.info(f"New user with username {user_name} added to the table")
                    handle_iam_user(user_name)
                elif record['eventName'] == 'REMOVE':
                    logger.info(f"User with username {user_name} removed from the table")
                    handle_iam_user_removal(user_name)
            return # Returning Function here so that we do not want cron-based trigger to run every time
        # Cron-based trigger
        dynamodb_users = []
        paginator = dynamodb_client.get_paginator('scan')
        for page in paginator.paginate(TableName=TABLE_NAME):
            for item in page['Items']:
                dynamodb_users.append(item['UserName']['S'])
        existing_iam_users = []
        paginator = iam_client.get_paginator('list_users')
        for page in paginator.paginate():
            for user in page['Users']:
                existing_iam_users.append(user['UserName'])

        if dynamodb_users:
            for user_name in dynamodb_users:
                logger.info(f"Handling user from DynamoDB: {user_name}")
                handle_iam_user(user_name)
        else:
            logger.info("DynamoDB table is empty. No users to be created or managed.")

        # Check and delete users not in the DynamoDB table
        delete_extra_iam_users(existing_iam_users, dynamodb_users) # This is run regardless of how the lambda is triggerd
    
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        raise

def handle_iam_user(user_name):
    try:
        # If IAM user doesn't exist, it'll throw an exception.
        iam_client.get_user(UserName=user_name)
        logger.info(f"IAM user {user_name} already exists.")
        current_key, pending_deletion_key = get_key_details(user_name)

        # Decision logic on how the keys should rotate
        if not current_key:
            logger.info("No key present, Creating current key")
            create_and_manage_key(user_name, 'current')
        elif current_key and not pending_deletion_key and current_key['age'] >= timedelta(days=2):
            logger.info("Current key age is older than 15 days, Creating New key and renaming keys")
            rotate_keys_and_update_tags(user_name, current_key, pending_deletion_key)
        elif current_key and pending_deletion_key and pending_deletion_key['age'] >= timedelta(days=4):
            logger.info("Key age expired, Rotationg keys")
            rotate_keys_and_update_tags(user_name, current_key, pending_deletion_key)
        else:
            logger.info(f"Keys are not old enough to rotate for the user {user_name}")

    except iam_client.exceptions.NoSuchEntityException:  # User doesn't exist
        try:
            logger.info(f"IAM user {user_name} doesn't exist. Creating...")
            # Create IAM user
            iam_client.create_user(UserName=user_name)

            # Attach permission boundary to the user
            account_id = boto3.client('sts').get_caller_identity().get('Account')
            permissions_boundary_arn = f"arn:aws:iam::{account_id}:policy/BCGOV_IAM_USER_BOUNDARY_POLICY"
            logger.info(f"Attaching permission boundary: {permissions_boundary_arn} to user: {user_name}")
            iam_client.put_user_permissions_boundary(UserName=user_name, PermissionsBoundary=permissions_boundary_arn)
            
            create_and_manage_key(user_name, 'current')
        except Exception as ex:
            logger.error(f"Error while creating user and attaching permission boundary: {str(ex)}")
            raise


def get_key_details(user_name):
    logger.info(f"Getting Key Details for the user: {user_name}")
    existing_keys = iam_client.list_access_keys(UserName=user_name)['AccessKeyMetadata']
    pending_deletion_key = None
    current_key = None
    
    for key in existing_keys:
        key_id = key['AccessKeyId']
        create_date = key['CreateDate']
        age = datetime.now(timezone.utc) - create_date
        
        tags = iam_client.list_user_tags(UserName=user_name)
        for tag in tags['Tags']:
            if tag['Key'] == key_id and tag['Value'] == 'pending_deletion':
                pending_deletion_key = {'id': key_id, 'age': age}
            elif tag['Key'] == key_id and tag['Value'] == 'current':
                current_key = {'id': key_id, 'age': age}
                
    return current_key, pending_deletion_key

def rotate_keys_and_update_tags(user_name, current_key, pending_deletion_key):
    logger.info(f"Rotating keys for user: {user_name}")
    
    # If there is a 'Pending deletion key' to delete
    if pending_deletion_key:
        # Untag and delete the 'Pending deletion key'
        iam_client.untag_user(UserName=user_name, TagKeys=[pending_deletion_key['id']])
        iam_client.delete_access_key(UserName=user_name, AccessKeyId=pending_deletion_key['id'])

    # Move 'current' key to 'pending_deletion' in Parameter Store
    param_name = f'/iam_users/{user_name}_keys'
    try:
        existing_param = ssm_client.get_parameter(Name=param_name, WithDecryption=True)['Parameter']['Value']
        existing_param = json.loads(existing_param)
        if 'current' in existing_param:
            existing_param['pending_deletion'] = existing_param['current']
            del existing_param['current']
        ssm_client.put_parameter(Name=param_name, Value=json.dumps(existing_param), Type='SecureString', Overwrite=True)
    except ssm_client.exceptions.ParameterNotFound:
        # No existing parameter to update
        pass
    
    # Untag the 'Current key' and tag as 'Pending deletion'
    iam_client.untag_user(UserName=user_name, TagKeys=[current_key['id']])
    iam_client.tag_user(UserName=user_name, Tags=[{'Key': current_key['id'], 'Value': 'pending_deletion'}])
    
    # Create a new 'Current key'
    create_and_manage_key(user_name, 'current')

def create_and_manage_key(user_name, key_status):
    logger.info(f"Creating a new {key_status} key for user: {user_name}")

    retries = 3
    for i in range(retries):
        try:
            new_key = iam_client.create_access_key(UserName=user_name)
            new_key_id = new_key['AccessKey']['AccessKeyId']
            break
        except iam_client.exceptions.LimitExceededException:
            if i < retries - 1:  # i is zero indexed
                logger.warning(f"Rate limit exceeded when creating key for {user_name}. Retrying...")
                time.sleep(2 ** i)  # Exponential back-off
            else:
                logger.error(f"Failed to create key for {user_name} after {retries} retries.")
                return
    
    tag_value = 'current' if key_status == 'current' else 'pending_deletion'
    iam_client.tag_user(UserName=user_name, Tags=[{'Key': new_key_id, 'Value': tag_value}])
    
    param_name = f'/iam_users/{user_name}_keys'
    param_value = {
        tag_value: {
            'AccessKeyID': new_key_id,
            'SecretAccessKey': new_key['AccessKey']['SecretAccessKey']
        }
    }
    try:
        existing_param = ssm_client.get_parameter(Name=param_name, WithDecryption=True)['Parameter']['Value']
        existing_param = json.loads(existing_param)
        existing_param.update(param_value)
        ssm_client.put_parameter(Name=param_name, Value=json.dumps(existing_param), Type='SecureString', Overwrite=True)
    except ssm_client.exceptions.ParameterNotFound:
        ssm_client.put_parameter(Name=param_name, Value=json.dumps(param_value), Type='SecureString')


def handle_iam_user_removal(user_name):
    try:
        # Detach permissions boundary from the user
        try:
            iam_client.delete_user_permissions_boundary(UserName=user_name)
            logger.info(f"Detached permissions boundary from IAM user: {user_name}")
        except iam_client.exceptions.NoSuchEntityException:
            # No permissions boundary was attached, so just move on
            logger.info(f"No permissions boundary attached to IAM user: {user_name}")

        # Detach all policies attached to the user
        attached_policies = iam_client.list_attached_user_policies(UserName=user_name)
        for policy in attached_policies['AttachedPolicies']:
            iam_client.detach_user_policy(UserName=user_name, PolicyArn=policy['PolicyArn'])
            logger.info(f"Detached policy {policy['PolicyArn']} from IAM user: {user_name}")            

        # Deactivate and delete all MFA devices associated with the user
        mfa_devices = iam_client.list_mfa_devices(UserName=user_name)
        for mfa_device in mfa_devices['MFADevices']:
            iam_client.deactivate_mfa_device(UserName=user_name, SerialNumber=mfa_device['SerialNumber'])
            logger.info(f"Deactivated MFA device {mfa_device['SerialNumber']} for IAM user: {user_name}")        
            
        # List and delete access keys associated with the user
        keys = iam_client.list_access_keys(UserName=user_name)
        for key in keys['AccessKeyMetadata']:
            iam_client.delete_access_key(UserName=user_name, AccessKeyId=key['AccessKeyId'])
        logger.info(f"Deleting IAM user: {user_name}")    
        iam_client.delete_user(UserName=user_name)

    except iam_client.exceptions.DeleteConflictException:
        logger.warning(f"IAM user {user_name} has attached resources. Manual cleanup required.")
        return
    except iam_client.exceptions.NoSuchEntityException:
        logger.info(f"IAM user {user_name} doesn't exist, skipping...")

    param_name = f'/iam_users/{user_name}_keys'
    try:
        logger.info(f"Deleting parameter for the IAM user: {user_name}")
        ssm_client.delete_parameter(Name=param_name)
    except ssm_client.exceptions.ParameterNotFound:
        logger.info(f"Parameter not found for the IAM user: {user_name}, skipping...")


# Saftey Net to handle potential drift between the IAM users in your AWS account and the users listed in the DynamoDB table.
def delete_extra_iam_users(existing_users, iam_users_from_db):
    """Delete IAM users which are not in the DynamoDB."""
    
    for user_name in existing_users:
        if user_name not in iam_users_from_db:
            logger.info(f"Extra IAM user found: {user_name}. Starting cleanup process...")
            handle_iam_user_removal(user_name)
