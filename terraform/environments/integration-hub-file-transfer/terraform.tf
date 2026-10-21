terraform {
  required_providers {
    aws = {
      version = ">= 6.28.0, < 7.0.0"
      source  = "hashicorp/aws"
    }
    external = {
      version = "2.4.2"
      source  = "hashicorp/external"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    local = {
      version = "2.9.1"
      source  = "hashicorp/local"
    }
    null = {
      version = "3.3.2"
      source  = "hashicorp/null"
    }
  }
  required_version = ">= 1.5.7, < 2.0.0"
}

# Provider for CRUD operations on IAM Identity Center Application group assignments
provider "aws" {
  region = "eu-west-2"
  alias  = "sso-application-assignment"

  assume_role {
    role_arn = "arn:aws:iam::${local.environment_management.aws_organizations_root_account_id}:role/ModernisationPlatformSSOApplicationAssignment"
    tags = {
      ApplicationAccount = data.aws_caller_identity.original_session.account_id
    }
  }
  default_tags { tags = local.tags }
}
