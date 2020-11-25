
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE) 

# AWS Workload Account Automation Setup

This repo contains a Terraform module that is part of the tooling to provision access for automation (CI/CD) tools to a project team's accounts within an AWS Landing Zone.

This module is used in conjunction with other modules that provide other "layers" to project accounts within a landing zone.  The modules are orchestrated using a `terragrunt` configuration that is contained in a private repository.     

## Third-Party Products/Libraries used and the licenses they are covered by

HashiCorp Terraform - [![License: MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)

## Project Status
- [x] Development
- [ ] Production/Maintenance

## How To Use

Note: This module is intended to be used by another "root" module, or as part of a `terragrunt` "stack" rather than on its own.  It doesn't do much on its own.

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
