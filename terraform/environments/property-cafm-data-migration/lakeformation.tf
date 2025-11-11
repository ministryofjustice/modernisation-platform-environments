# Role used by DE's to access AWS
data "aws_iam_roles" "modernisation_platform" {
  name_regex  = "AWSReservedSSO_modernisation-platform-developer_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = [
    one(data.aws_iam_roles.modernisation_platform.arns),
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess"
  ]

  parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }
}
