data "aws_iam_roles" "sso_platform_engineer_admin" {
  name_regex  = "AWSReservedSSO_platform-engineer-admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}
