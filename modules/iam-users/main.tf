# Create an Empty IAM user
resource "aws_iam_user" "service_account" {
  for_each = toset(var.service_accounts)
  name     = each.value
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
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:ListAccessKeys",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:ListUserTags"
        ],
        Resource = "arn:aws:iam::*:user/${aws_iam_user.this.name}"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:UpdateSecret"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_permissions_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}

# Create a Lambda function
resource "aws_lambda_function" "key_rotation" {
  function_name = var.function_name
  filename      = "./lambda/lambda.py"
  handler       = "lambda.lambda_handler" # Modify this based on your specific handler configuration
  runtime       = "Python 3.11"
  role          = aws_iam_role.lambda_exec_role.arn
}

# Create a Cloud watch event rule for every 5 minutes
resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  schedule_expression = "rate(5 minutes)"
}

# Set the Lambda function to run every 5 minutes
resource "aws_cloudwatch_event_target" "every_five_minutes_target" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "LambdaFunction"
  arn       = aws_lambda_function.key_rotation.arn
}

# Create a Cloudwatch event rule to detect IAM User Creation
resource "aws_cloudwatch_event_rule" "iam_user_creation" {
  name = "iam-user-creation"
  event_pattern = jsonencode({
    "source" : ["aws.iam"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["iam.amazonaws.com"],
      "eventName" : ["CreateUser"]
    }
  })
}

# Set the Lambda function to run when IAM User is Created
resource "aws_cloudwatch_event_target" "iam_user_creation_target" {
  rule      = aws_cloudwatch_event_rule.iam_user_creation.name
  target_id = "LambdaFunction"
  arn       = aws_lambda_function.key_rotation.arn
}