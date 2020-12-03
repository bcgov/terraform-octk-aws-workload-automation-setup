//module outputs should be defined and documented here.
output "access_key_id" {
	value = aws_iam_access_key.terraform_automation_project_user_access_key.id
}

output "secret_access_key" {
	value = aws_iam_access_key.terraform_automation_project_user_access_key.encrypted_secret
}
