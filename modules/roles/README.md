<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.policy_arns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.policy_json](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_iam_user_arns"></a> [iam\_user\_arns](#input\_iam\_user\_arns) | List of ARNs of AWS IAM user allowed to assume role | `list(string)` | n/a | yes |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | Name of the permissions\_boundary attached | `string` | n/a | yes |
| <a name="input_policy_arns"></a> [policy\_arns](#input\_policy\_arns) | List of AWS policy ARNs | `list(string)` | `[]` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | AWS policy JSON string | `string` | `"{}"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the AWS role to create and attach policy on | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | n/a |
<!-- END_TF_DOCS -->