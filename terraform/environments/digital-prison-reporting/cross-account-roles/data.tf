data "aws_iam_role" "dataapi_cross_role" {
  name = "dpr-data-api-cross-account-role"
}

data "aws_iam_roles" "data_engineering_roles" {
  count = local.is-test ? 0 : 1

  name_regex = "AWSReservedSSO_modernisation-platform-data-eng.*"
}

data "aws_iam_roles" "analytics_engineering_roles" {
  count = local.is-test || local.is-development ? 0 : 1

  name_regex = "AWSReservedSSO_mp-analytics-engineering.*"
}
