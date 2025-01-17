terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
  }
  required_version = "~> 1.0"
}

provider "awscc" {
  assume_role = {
    role_arn = !can(regex("githubactionsrolesession|AdministratorAccess|user", data.aws_caller_identity.original_session.arn)) ? null : can(regex("user", data.aws_caller_identity.original_session.arn)) ? "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/${var.collaborator_access}" : "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess",
    # session_name = "SESSION_NAME"
    # external_id  = "EXTERNAL_ID"
  }
}


