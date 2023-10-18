variable "function_name" {
  description = "Name of the lambda function"
}

variable "service_accounts" {
  description = "List of service accounts to create as IAM users"
  type        = list(string)
  default     = []
}

variable "role_name" {
  description = "Name of the role created for the lambda function"
}

variable "policy_name" {
  description = "Name of the policy created for the lambda function"
}
