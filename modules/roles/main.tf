resource "aws_iam_role" "this" {
  name               = var.role_name
  permissions_boundary = aws_iam_policy.bcgov_perm_boundary.arn
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": ${jsonencode(var.iam_user_arns)}
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_policy" "bcgov_perm_boundary" {
  name        = "BCGOV_Permission_Boundary_Automation"
  description = "Policy to restrict actions on BCGov Resources"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
        Sid      = "AllowAdminAccess"
      },
      {
        Action   = "iam:*Provider"
        Effect   = "Deny"
        Resource = "*"
        Sid      = "DenyPermBoundaryBCGovIDPAlteration"
      },
      {
        Action = [
          "iam:Create*",
          "iam:Update*",
          "iam:Delete*",
          "iam:DetachRolePolicy",
          "iam:DeleteRolePolicy"
        ]
        Effect = "Deny"
        Resource = [
          "arn:aws:iam::*:policy/BCGOV*",
          "arn:aws:iam::*:role/CloudCustodian",
          "arn:aws:iam::*:role/AWSCloudFormationStackSetExecutionRole",
          "arn:aws:iam::*:role/*BCGOV*",
          "arn:aws:iam::*:instance-profile/EC2-Default-SSM-AD-Role-ip"

        ]
        Sid = "DenyPermBoundaryBCGovAlteration"
      },
      {
        Action = [
          "budgets:DeleteBudgetAction",
          "budgets:UpdateBudgetAction",
          "budgets:ModifyBudget"
        ]
        Effect   = "Deny"
        Resource = "arn:aws:budgets::*:budget/Default*"
        Sid      = "DenyDefaultBudgetAlteration"
      },
      {
        Action = [
          "iam:DeleteInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ]
        Effect   = "Deny"
        Resource = "arn:aws:iam::*:instance-profile/EC2-Default-SSM-AD-Role-ip"
        Sid      = "DenyDefaultInstanceProfileAlteration"
      },
      {
        Action = [
          "kms:ScheduleKeyDeletion",
          "kms:DeleteAlias",
          "kms:DisableKey",
          "kms:UpdateAlias"
        ]
        Effect   = "Deny"
        Resource = "*"
        Condition = {
          "ForAnyValue:StringEquals" = {
            "aws:ResourceTag/Accelerator" = "PBMM"
          }
        }
        Sid = "DenyDefaultKMSAlteration"
      },
      {
        Action = [
          "ssm:DeleteParameter*",
          "ssm:PutParameter"
        ],
        Effect = "Deny",
        "Resource" : [
          "arn:aws:ssm:*:*:parameter/cdk-bootstrap/pbmmaccel/*",
          "arn:aws:ssm:*:*:parameter/octk/*"
        ],
        Sid = "DenyDefaultParameterStoreAlteration"
      },
      {
        Action = [
          "secretsmanager:DeleteSecret",
          "secretsmanager:CreateSecret",
          "secretsmanager:UpdateSecret"
        ]
        Effect   = "Deny"
        Resource = "arn:aws:secretsmanager:*:*:secret:accelerator*"
        Sid      = "DenyDefaultSecretManagerAlteration"
      }
    ]
  })
}

resource "aws_iam_policy" "this" {
  count  = var.policy_json == "{}" ? 0 : 1
  name   = "${var.role_name}_inline_policy"
  policy = var.policy_json
}

resource "aws_iam_role_policy_attachment" "policy_arns" {
  for_each   = toset(var.policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.key
}

resource "aws_iam_role_policy_attachment" "policy_json" {
  for_each   = { for policy in aws_iam_policy.this : policy.name => policy.arn }
  role       = aws_iam_role.this.name
  policy_arn = each.value
}
