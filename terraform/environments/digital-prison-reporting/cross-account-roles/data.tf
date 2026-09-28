data "aws_iam_role" "dataapi_cross_role" {
  count = local.is-test ? 0 : 1

  name = "dpr-data-api-cross-account-role"
}
