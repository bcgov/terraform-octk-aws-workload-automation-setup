variable "name" {
  type        = string
  description = "The name of the budget."
}

variable "amount" {
  type        = string
  description = "The amount of the budget."
}

variable "currency" {
  type        = string
  description = "The currency of the budget (only USD is supported)."
  default     = "USD"
}

variable "email_recipients" {
  type        = list(string)
  description = "A list of email addresses to send the budget notifications to."
}

variable "threshold_percentages" {
  type        = list(number)
  description = "A list of percentages to trigger notifications."
  default     = [80, 100]
}
