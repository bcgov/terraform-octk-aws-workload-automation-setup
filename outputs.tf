//module outputs should be defined and documented here.
output "access_key_id" {
  value = aws_iam_access_key.terraform_automation_project_user_access_key.id
}

output "secret_access_key" {
  value = aws_iam_access_key.terraform_automation_project_user_access_key.encrypted_secret
}

output "extra_sa_access_keys" {
  value = {
    for sa in var.extra_service_accounts : sa => {
      access_key_id     = aws_iam_access_key.extra_project_user_access_key[sa].id
      access_key_secret = aws_iam_access_key.extra_project_user_access_key[sa].secret
    }
  }
}
