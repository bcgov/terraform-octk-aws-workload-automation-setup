variable iam_security_account_name {
    description = "IAM Security Account Name"
	default = "iam-security"
}

variable project_name {
    description = "Project prefix (aka license plate)."
}

variable "automation_role_name" {
	default = "OrganizationAccountAccessRole"
	description = "The role used for executing automation commands in the environment."
	type = string
}

variable "pgp_key" {
	type = string
	description = "A base64 string containing the pgp key to use to encrypt the secret access key."
}
