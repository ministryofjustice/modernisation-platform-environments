data "aws_iam_roles" "platform_engineer_admin_sso_role" {
  name_regex  = "AWSReservedSSO_platform-engineer-admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "sandbox_sso_role" {
  name_regex  = "AWSReservedSSO_modernisation-platform-sandbox_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
