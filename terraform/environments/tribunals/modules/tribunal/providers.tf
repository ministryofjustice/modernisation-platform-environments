provider "aws" {
  alias  = "core-vpc"
  region = "eu-west-2"
  assume_role {
    role_arn = !can(regex("githubactionsrolesession|AdministratorAccess", data.aws_caller_identity.original_session.arn)) ? "arn:aws:iam::${local.environment_management.account_ids[local.provider_name]}:role/member-delegation-read-only" : "arn:aws:iam::${local.environment_management.account_ids[local.provider_name]}:role/member-delegation-${local.vpc_name}-${local.environment}"
  }
}