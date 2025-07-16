
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE) 

# AWS Workload Account Automation Setup

This repo contains a Terraform module that is part of the tooling to provision access for automation (CI/CD) tools to a project team's accounts within an AWS Landing Zone.

This module is used in conjunction with other modules that provide other "layers" to project accounts within a landing zone.  The modules are orchestrated using a `terragrunt` configuration that is contained in a private repository.     

## Third-Party Products/Libraries used and the licenses they are covered by

HashiCorp Terraform - [![License: MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)

## Project Status
- [x] Development
- [ ] Production/Maintenance

# How To Use

Note: This module is intended to be used by another "root" module, or as part of a `terragrunt` "stack" rather than on its own.  It doesn't do much on its own.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.57.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.iam-security-account"></a> [aws.iam-security-account](#provider\_aws.iam-security-account) | 5.57.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lz_info"></a> [lz\_info](#module\_lz\_info) | github.com/BCDevOps/terraform-aws-sea-organization-info | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_access_key.project_user_access_key](https://registry.terraform.io/providers/hashicorp/aws/5.57.0/docs/resources/iam_access_key) | resource |
| [aws_iam_access_key.terraform_automation_project_user_access_key](https://registry.terraform.io/providers/hashicorp/aws/5.57.0/docs/resources/iam_access_key) | resource |
| [aws_iam_user.project_user](https://registry.terraform.io/providers/hashicorp/aws/5.57.0/docs/resources/iam_user) | resource |
| [aws_iam_user.terraform_automation_project_user](https://registry.terraform.io/providers/hashicorp/aws/5.57.0/docs/resources/iam_user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_automation_role_name"></a> [automation\_role\_name](#input\_automation\_role\_name) | The role used for executing automation commands in the environment. | `string` | `"OrganizationAccountAccessRole"` | no |
| <a name="input_iam_security_account_name"></a> [iam\_security\_account\_name](#input\_iam\_security\_account\_name) | IAM Security Account Name | `string` | `"iam-security"` | no |
| <a name="input_project_config"></a> [project\_config](#input\_project\_config) | project.json config. | `any` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project prefix (aka license plate). | `any` | n/a | yes |
| <a name="input_project_service_accounts"></a> [project\_service\_accounts](#input\_project\_service\_accounts) | A list of names for addtional custom iam user service accounts. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_key_id"></a> [access\_key\_id](#output\_access\_key\_id) | module outputs should be defined and documented here. |
| <a name="output_project_sa_access_keys"></a> [project\_sa\_access\_keys](#output\_project\_sa\_access\_keys) | n/a |
| <a name="output_secret_access_key"></a> [secret\_access\_key](#output\_secret\_access\_key) | n/a |
<!-- END_TF_DOCS -->

## Getting Help or Reporting an Issue
<!--- Example below, modify accordingly --->
To report bugs/issues/feature requests, please file an [issue](../../issues).


## How to Contribute
<!--- Example below, modify accordingly --->
If you would like to contribute, please see our [CONTRIBUTING](./CONTRIBUTING.md) guidelines.

Please note that this project is released with a [Contributor Code of Conduct](./CODE_OF_CONDUCT.md). 
By participating in this project you agree to abide by its terms.


## License
    Copyright 2018 Province of British Columbia

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
