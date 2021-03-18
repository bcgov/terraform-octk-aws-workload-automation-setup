resource "aws_iam_role" "this" {
  name               = var.role_name
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
