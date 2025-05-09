# Provider Alias for retrieving delius-core resources
# provider "aws" {
#   region = "eu-west-2"
#   alias  = "delius-core"
#   assume_role {
#     role_arn = !can(regex("githubactionsrolesession|AdministratorAccess|user", data.aws_caller_identity.original_session.arn)) ? null : can(regex("user", data.aws_caller_identity.original_session.arn)) ? "arn:aws:iam::${local.environment_management.account_ids[local.temp]}:role/${var.collaborator_access}" : "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
#   }
# }

provider "aws" {
  region = "eu-west-2"
  alias  = "delius-core"
  assume_role {
    role_arn = "arn:aws:iam::${local.environment_management.account_ids[local.temp]}:role/dev-alresco-read-only"
  }
}

locals {
    temp = "delius-core-development"
}