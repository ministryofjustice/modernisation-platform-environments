data "aws_iam_roles" "sso_platform_engineer_admin" {
  name_regex  = "AWSReservedSSO_platform-engineer-admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "http" "test_data_csv" {
  url = local.test_data_csv
}
