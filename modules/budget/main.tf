resource "aws_budgets_budget" "this" {
  name         = var.name
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = var.amount
  limit_unit   = var.currency
  cost_types {
    include_credit             = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = true
    include_subscription       = true
    include_support            = true
    include_tax                = true
    include_upfront            = true
    use_amortized              = false
  }

  dynamic "notification" {
    for_each = toset(var.threshold_percentages)
    content {
      comparison_operator        = "GREATER_THAN"
      notification_type          = "ACTUAL"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = var.email_recipients
    }
  }
}
