# Create DynamoDB table for clients to add entries
resource "aws_dynamodb_table" "service_account_table" {
  name           = var.table_name # Update with your preferred table name
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "UserName"

  attribute {
    name = "UserName"
    type = "S"
  }

  # Enabling Stream for New Image (captures new entries)
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

# DynamoDB Stream to Lambda Event Source Mapping
resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn  = aws_dynamodb_table.service_account_table.stream_arn
  function_name     = aws_lambda_function.key_rotation.function_name
  starting_position = "TRIM_HORIZON"
}


# Create an IAM role for the lambda function that rotates keys
resource "aws_iam_role" "lambda_exec_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM Policy with required permissions to run the lambda function
resource "aws_iam_policy" "lambda_permissions" {
  name        = var.policy_name
  description = "Permissions for Lambda to manage IAM keys, Secrets in Secrets Manager, and IAM user tags."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:ListUsers",
          "iam:GetUser",
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:ListAttachedUserPolicies",
          "iam:ListMFADevices",
          "iam:DeactivateMFADevice",
          "iam:DetachUserPolicy",
          "iam:ListAccessKeys",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:ListUserTags",
          "iam:PutUserPermissionsBoundary",
          "iam:DeleteUserPermissionsBoundary"
        ],
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:DeleteParameter"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach the policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_permissions_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda.py"
  output_path = "${path.module}/lambda/lambda.zip"
}
# Create a Lambda function
resource "aws_lambda_function" "key_rotation" {
  function_name    = var.function_name
  filename         = data.archive_file.lambda_zip.output_path
  handler          = "lambda.lambda_handler" # Modify this based on your specific handler configuration
  runtime          = "python3.9"
  timeout          = 300
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_exec_role.arn
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.service_account_table.name
    }
  }
}
# Create a cloudwatch alarm that monitors IAM users lambda failures
resource "aws_cloudwatch_metric_alarm" "key_rotation_lambda_function" {
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  datapoints_to_alarm = "1"
  alarm_description   = "Monitor IAM users lambda for errors"
  alarm_actions       = [var.sns_arn]
  dimensions = {
    FunctionName = var.function_name
  }
}
# Create a Cloud watch event rule for every 5 minutes
resource "aws_cloudwatch_event_rule" "every_hour" {
  name                = "every-hour"
  schedule_expression = "rate(1 hour)"
}

# Set the Lambda function to run every 5 minutes
resource "aws_cloudwatch_event_target" "every_hour_target" {
  rule      = aws_cloudwatch_event_rule.every_hour.name
  target_id = "LambdaFunction"
  arn       = aws_lambda_function.key_rotation.arn
}

# Grant permission for the every-five-minutes event to invoke the Lambda function
resource "aws_lambda_permission" "allow_cloudwatch_every_five_minutes" {
  statement_id  = "AllowExecutionFromCloudWatchEveryFiveMinutes"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.key_rotation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_hour.arn
}

# Permission boundary
resource "aws_iam_policy" "user_access_boundary" {
  name        = "BCGOV_IAM_USER_BOUNDARY_POLICY"
  path        = "/"
  description = "Permission boundary policy for the BC Gov IAM user service"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "S3FullAccess",
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = "*"
      },
      {
        Sid      = "SESFullAccess",
        Effect   = "Allow",
        Action   = "ses:*",
        Resource = "*"
      },
      {
        Sid      = "BedrockFullAccess",
        Effect   = "Allow",
        Action   = "bedrock:*",
        Resource = "*"
      },
      {
        Sid    = "SSMandKMSAccess",
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "kms:Decrypt"
        ],
        Resource = [
          "arn:aws:ssm:*:*:parameter/iam_users/*",
          "arn:aws:kms:*:*:key/*"
        ]
      }
    ]
  })
}
