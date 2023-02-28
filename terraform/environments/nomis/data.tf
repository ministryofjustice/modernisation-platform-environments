# Get session information from OIDC provider
data "aws_caller_identity" "oidc_session" {
  provider = aws.oidc-session
}

data "aws_iam_session_context" "whoami" {
  provider = aws.oidc-session
  arn      = data.aws_caller_identity.oidc_session.arn
}

# This account id
data "aws_caller_identity" "current" {}

# Infrastructure CICD role
data "aws_iam_role" "member_infrastructure_access" {
  name = "MemberInfrastructureAccess"
}
