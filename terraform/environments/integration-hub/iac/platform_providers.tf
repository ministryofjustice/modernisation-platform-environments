provider "aws" {
  alias  = "original-session"
  region = "eu-west-2"
  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn = !can(regex("githubactionsrolesession|AdministratorAccess|user", data.aws_caller_identity.original_session.arn)) ? null : can(regex("user", data.aws_caller_identity.original_session.arn)) ? "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/${var.collaborator_access}" : "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
  }

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias  = "modernisation-platform"
  region = "eu-west-2"

  assume_role {
    role_arn = "arn:aws:iam::${local.modernisation_platform_account_id}:role/modernisation-account-limited-read-member-access"
  }

  default_tags {
    tags = local.tags
  }
}
