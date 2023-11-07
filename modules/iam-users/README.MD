# AWS IAM User Management with Lambda and DynamoDB

This documentation outlines the process of creating and managing AWS IAM users using a serverless architecture consisting of AWS Lambda, DynamoDB, and SSM Parameter Store. The solution provides automated user creation, access key rotation, and user deletion based on entries within a DynamoDB table.

## Architecture Overview

The process is driven by a Lambda function which is triggered by two distinct events:

1. **DynamoDB Stream:** The function is invoked in response to item-level changes in the DynamoDB table. It creates, manages, or deletes IAM users based on the nature of the change (insert, modify, or remove).

2. **Scheduled Event:** A CloudWatch Events rule triggers the Lambda function every hour to perform key rotation and cleanup tasks for the IAM users.

The Lambda function interacts with the DynamoDB table, IAM, and SSM Parameter Store, conducting the following operations:

- Creating IAM users and their access keys.
- Managing IAM user keys by rotating them when necessary.
- Storing access key details securely in the SSM Parameter Store.
- Deleting IAM users and their associated keys when removed from the DynamoDB table.

## Terraform Configuration

The Terraform configuration is responsible for setting up the following AWS resources:

- **DynamoDB Table:** Stores IAM user details and triggers the Lambda function via stream records.
- **Lambda Function:** Executes the logic for IAM user and key management.
- **CloudWatch Event Rule:** Schedules the Lambda function to run at a specified frequency.
- **IAM Roles and Policies:** Provides necessary permissions for the Lambda function to interact with other AWS services.

## Lambda Function Logic

### Trigger Handling

- **DynamoDB Stream Invocation:** On INSERT or MODIFY events, `handle_iam_user` is called to create or update IAM users. On REMOVE events, `handle_iam_user_removal` is called to delete IAM users.

- **Scheduled Invocation:** The function checks for key rotation requirements for all users listed in the DynamoDB table and deletes any IAM users not present in the table to maintain consistency.

### User and Key Management Functions

- `lambda_handler`: The primary entry point for the Lambda function. It determines the trigger type and calls relevant functions accordingly.

- `handle_iam_user`: Manages user creation and key rotation. If an IAM user doesn't exist, it's created along with their keys. If the current key is older than 15 days, a new key is generated, and the old key is marked for deletion. When a key marked as pending deletion reaches 30 days of age, it is deleted.

- `get_key_details`: Retrieves details of the user's access keys and their respective ages and tags.

- `rotate_keys_and_update_tags`: Handles the access key rotation logic and updates the tags and SSM Parameter Store accordingly.

- `create_and_manage_key`: Creates new access keys for IAM users and stores the key details in the SSM Parameter Store.

- `handle_iam_user_removal`: Removes IAM users and their access keys. Deletes the SSM Parameter Store entry corresponding to the user's access keys.

- `delete_extra_iam_users`: A safety net function to ensure the synchronization between the IAM users in the AWS account and the DynamoDB table.

## Security Considerations

- The Lambda function uses a permissions boundary policy to restrict the maximum permissions IAM users can obtain, mitigating the risk of privilege escalation.

- Access key details are stored securely in the SSM Parameter Store with encryption enabled.


## Deployment

To deploy the solution:

- The solution is deployed from the automation layer and all the variables are passed in from the automation layer terragrunt file

## Usage

### Adding a New IAM User

1. Insert a new item into the DynamoDB table with the `UserName` attribute.
2. The Lambda function will automatically trigger and create an IAM user with the specified name.

### User Key Rotation

The function will automatically check the age of the access keys:

- If the current key is older than 15 days, it will create a new key and mark the old key for deletion.
- If a key marked for deletion is 30 days old, it will be deleted.

### Deleting an IAM User

Remove the corresponding entry from the DynamoDB table. The Lambda function will trigger and delete the user and their access keys from IAM and the SSM Parameter Store.



