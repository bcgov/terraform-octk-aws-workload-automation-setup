variable "iam_user_arns" {
  description = "List of ARNs of AWS IAM user allowed to assume role"
  type        = list(string)
}

variable "role_name" {
  description = "Name of the AWS role to create and attach policy on"
}

variable "policy_arns" {
  description = "List of AWS policy ARNs"
  type        = list(string)
  default     = []
}

variable "policy_json" {
  description = "AWS policy JSON string"
  type        = string
  default     = ""
}
