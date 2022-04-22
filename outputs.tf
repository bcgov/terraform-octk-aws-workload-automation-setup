//module outputs should be defined and documented here.
output "access_key_id" {
  value = aws_iam_access_key.terraform_automation_project_user_access_key.id
}

output "secret_access_key" {
  sensitive = true
  value     = aws_iam_access_key.terraform_automation_project_user_access_key.secret
}

output "project_sa_access_keys" {
  sensitive = true
  value = {
    for sa in var.project_service_accounts : sa => {
      access_key_id     = aws_iam_access_key.project_user_access_key[sa].id
      access_key_secret = aws_iam_access_key.project_user_access_key[sa].secret
    }
  }
}
