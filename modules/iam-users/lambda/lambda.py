import json
import boto3
from datetime import datetime, timezone, timedelta

def lambda_handler(event, context):
    iam_client = boto3.client('iam')
    secrets_manager_client = boto3.client('secretsmanager')

    users = iam_client.list_users()
    for user in users['Users']:
        user_name = user['UserName']
        print(f"Handling user: {user_name}")
        
        existing_keys = iam_client.list_access_keys(UserName=user_name)['AccessKeyMetadata']
        pending_deletion_key = None
        current_key = None
        
        for key in existing_keys:
            key_id = key['AccessKeyId']
            create_date = key['CreateDate']
            age = (datetime.now(timezone.utc) - create_date).total_seconds() // 60  # age in minutes
            
            print(f"Found existing key: {key_id}, Age: {age} minutes")
            
            tags = iam_client.list_user_tags(UserName=user_name)
            for tag in tags['Tags']:
                if tag['Key'] == key_id and tag['Value'] == 'pending_deletion':
                    pending_deletion_key = {'id': key_id, 'age': age}
                    print(f"Key {key_id} is tagged as 'pending deletion'")
                elif tag['Key'] == key_id and tag['Value'] == 'current':
                    current_key = {'id': key_id, 'age': age}
                    print(f"Key {key_id} is tagged as 'current'")
        
        # Decision logic
        if not current_key:
            print("No current key found. Creating 'current key'...")
            create_and_manage_key(user_name, 'current', iam_client, secrets_manager_client)
        elif current_key and current_key['age'] >= 5:
            print("'current key' is old enough. Creating new 'current key' and renaming old as 'Pending deletion key'...")
            rotate_keys_and_update_tags(user_name, current_key, pending_deletion_key, iam_client, secrets_manager_client)
        elif current_key and pending_deletion_key and pending_deletion_key['age'] >= 10:
            print(f"Rotating keys for user: {user_name}")
            rotate_keys_and_update_tags(user_name, current_key, pending_deletion_key, iam_client, secrets_manager_client)
        else:
            print(f"Waiting for keys to age for user: {user_name}")


def rotate_keys_and_update_tags(user_name, current_key, pending_deletion_key, iam_client, secrets_manager_client):
    secret_id = f'{user_name}_keys'
    
    # Check if there is a 'Pending deletion key' to delete
    if pending_deletion_key:
        # Untag the 'Pending deletion key' before deleting
        iam_client.untag_user(UserName=user_name, TagKeys=[pending_deletion_key['id']])
        iam_client.delete_access_key(UserName=user_name, AccessKeyId=pending_deletion_key['id'])
    
    # Get the existing secret and prepare it for updates.
    existing_secret = secrets_manager_client.get_secret_value(SecretId=secret_id)['SecretString']
    existing_secret = json.loads(existing_secret)  # Convert string back to dictionary
    
    # Move 'current' key values to 'pending_deletion'
    if 'current' in existing_secret:
        existing_secret['pending_deletion'] = existing_secret['current']
    
    secrets_manager_client.put_secret_value(SecretId=secret_id, SecretString=json.dumps(existing_secret))
    
    # Untag the 'Current key' from 'current' and tag as 'Pending deletion'
    iam_client.untag_user(UserName=user_name, TagKeys=[current_key['id']])
    iam_client.tag_user(UserName=user_name, Tags=[{'Key': current_key['id'], 'Value': 'pending_deletion'}])
    
    # Create new 'Current key' and update secret accordingly
    create_and_manage_key(user_name, 'current', iam_client, secrets_manager_client)
    
    print(f"Rotated keys for user {user_name}. Renamed 'Current key', and created a new 'Current key'.")




def create_and_manage_key(user_name, key_status, iam_client, secrets_manager_client):
    if key_status not in ['current', 'pending_deletion']:
        raise ValueError("Invalid key status. Should be either 'current' or 'pending_deletion'")
    
    new_key = iam_client.create_access_key(UserName=user_name)
    new_key_id = new_key['AccessKey']['AccessKeyId']
    
    tag_value = 'current' if key_status == 'current' else 'pending_deletion'
    iam_client.tag_user(UserName=user_name, Tags=[{'Key': new_key_id, 'Value': tag_value}])
    
    secret_id = f'{user_name}_keys'
    
    secret_value = {
        tag_value: {
            'AccessKeyID': new_key_id,
            'SecretAccessKey': new_key['AccessKey']['SecretAccessKey']
        }
    }
    
    try:
        existing_secret = secrets_manager_client.get_secret_value(SecretId=secret_id)['SecretString']
        existing_secret = json.loads(existing_secret)
        existing_secret.update(secret_value)
        secrets_manager_client.put_secret_value(SecretId=secret_id, SecretString=json.dumps(existing_secret))
    except secrets_manager_client.exceptions.ResourceNotFoundException:
        secrets_manager_client.create_secret(Name=secret_id, SecretString=json.dumps(secret_value))
    
    print(f"Created, tagged, and stored new key {new_key_id} as {tag_value}")
    return {'id': new_key_id, 'SecretAccessKey': new_key['AccessKey']['SecretAccessKey']}
