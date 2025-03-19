data "aws_availability_zones" "available" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}

data "aws_security_group" "quicksight_shared_vpc_security_group" {
  id = "quicksight-shared-vpc"
}
