# caller account information to instantiate aws.oidc provider
data "aws_caller_identity" "original_session" {
  provider = aws.original-session
}

# AWS provider for the original session which you connect with
provider "aws" {
  alias  = "original-session"
  region = "eu-west-2"
}

provider "aws" {
  alias  = "core-vpc"
  region = "eu-west-2"
  assume_role {
    role_arn = !can(regex("githubactionsrolesession|AdministratorAccess", data.aws_caller_identity.original_session.arn)) ? "arn:aws:iam::${local.environment_management.account_ids[local.provider_name]}:role/member-delegation-read-only" : "arn:aws:iam::${local.environment_management.account_ids[local.provider_name]}:role/member-delegation-${local.vpc_name}-${local.environment}"
  }
}