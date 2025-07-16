<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.57.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.57.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_budgets_budget.this](https://registry.terraform.io/providers/hashicorp/aws/5.57.0/docs/resources/budgets_budget) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amount"></a> [amount](#input\_amount) | The amount of the budget. | `string` | n/a | yes |
| <a name="input_currency"></a> [currency](#input\_currency) | The currency of the budget (only USD is supported). | `string` | `"USD"` | no |
| <a name="input_email_recipients"></a> [email\_recipients](#input\_email\_recipients) | A list of email addresses to send the budget notifications to. | `list(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the budget. | `string` | n/a | yes |
| <a name="input_threshold_percentages"></a> [threshold\_percentages](#input\_threshold\_percentages) | A list of percentages to trigger notifications. | `list(number)` | <pre>[<br>  50,<br>  80,<br>  100<br>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->