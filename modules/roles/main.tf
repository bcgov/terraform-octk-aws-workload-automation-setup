resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${var.iam_user_arn}"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "this" {
  for_each = { for policy in var.policies : policy.name => policy }
  name     = each.key
  policy   = jsonencode(each.value.inline_policy)
}

resource "aws_iam_role_policy_attachment" "policy_arns" {
  for_each   = toset(var.policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.key
}

resource "aws_iam_role_policy_attachment" "policies" {
  for_each   = aws_iam_policy.this
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[each.key].arn
}
