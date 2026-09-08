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
