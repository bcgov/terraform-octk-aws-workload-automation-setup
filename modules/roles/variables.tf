variable "iam_user_arn" {
  description = "ARN of AWS IAM user allowed to assume role"
}

variable "role_name" {
  description = "Name of the AWS role to create and attach policy on"
}

variable "policy_arns" {
  description = "List of AWS policy ARNs"
  type        = list(string)
  default     = []
}

variable "policies" {
  description = "List of AWS policies"
  default     = []
}
