provider "aws" {
  region = "eu-west-1"
  alias  = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
  }
}
