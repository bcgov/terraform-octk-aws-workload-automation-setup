terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.11.0"
    }
  }
}

provider "aws" {
  region  = "ca-central-1"
  alias   = "master"
  profile = "sea-terraform-automation"
}

module "lz_info" {
  source = "github.com/BCDevOps/terraform-aws-sea-organization-info"
  providers = {
    aws = aws.master
  }
}

locals {
  core_accounts    = { for account in module.lz_info.core_accounts : account.name => account }
  security_account = local.core_accounts[var.iam_security_account_name]
  project_config   = jsondecode(var.project_config)
  project_accounts = { for account in local.project_config.accounts : account.environment => account }
}

provider "aws" {
  region  = "ca-central-1"
  alias   = "iam-security-account"
  profile = "sea-terraform-automation"

  assume_role {
    role_arn     = "arn:aws:iam::${local.security_account.id}:role/${var.automation_role_name}"
    session_name = "slz-terraform-automation"
  }
}

resource "aws_iam_user" "terraform_automation_project_user" {
  provider = aws.iam-security-account
  name     = "BCGOV_Project_Automation_Account_${var.project_name}"
  path     = "/project-service-accounts/"
}

resource "aws_iam_access_key" "terraform_automation_project_user_access_key" {
  provider = aws.iam-security-account
  user     = aws_iam_user.terraform_automation_project_user.name
  pgp_key  = var.pgp_key
}

resource "aws_iam_user" "extra_project_user" {
  for_each = toset(var.extra_service_accounts)
  provider = aws.iam-security-account
  name     = "BCGOV_Project_User_${each.key}_${var.project_name}"
  path     = "/project-service-accounts/"
}

resource "aws_iam_access_key" "extra_project_user_access_key" {
  for_each = toset(var.extra_service_accounts)
  provider = aws.iam-security-account
  user     = aws_iam_user.extra_project_user[each.key].name
  # pgp_key  = var.pgp_key
}

