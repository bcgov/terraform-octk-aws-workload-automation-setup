variable "iam_security_account_name" {
  description = "IAM Security Account Name"
  default     = "iam-security"
}

variable "project_name" {
  description = "Project prefix (aka license plate)."
}

variable "project_config" {
  description = "project.json config."
}

variable "project_service_accounts" {
  type        = list(string)
  description = "A list of names for addtional custom iam user service accounts."
}

variable "automation_role_name" {
  default     = "OrganizationAccountAccessRole"
  description = "The role used for executing automation commands in the environment."
  type        = string

