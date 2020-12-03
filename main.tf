terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = "3.11.0"
		}
	}
}

provider "aws" {
	version = "~> 3.11"
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

	core_accounts = { for account in module.lz_info.core_accounts : account.name =>  account }

	security_account = local.core_accounts[var.iam_security_account_name]
}

provider "aws" {
	version = "~> 3.11"
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
	name = "BCGOV_Project_Automation_Account_${var.project_name}"
	path = "/project-service-accounts/"
}

resource "aws_iam_access_key" "terraform_automation_project_user_access_key" {
	provider = aws.iam-security-account
	user = aws_iam_user.terraform_automation_project_user.name
	pgp_key = var.pgp_key
}


