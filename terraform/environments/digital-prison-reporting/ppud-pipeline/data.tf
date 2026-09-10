data "aws_secretsmanager_secret" "ppud_slack_webhook" {
  count = local.is-test ? 0 : 1

  name = module.ppud_slack_webhook[0].secret_id
}

data "aws_secretsmanager_secret_version" "ppud_slack_webhook" {
  count = local.is-test ? 0 : 1

  secret_id = data.aws_secretsmanager_secret.ppud_slack_webhook[0].id
}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_iam_roles" "data_engineering_roles" {
  name_regex = "AWSReservedSSO_modernisation-platform-data-eng.*"
}

data "aws_iam_role" "analytical_platform_share_role" {
  for_each = local.analytical_platform_share

  name = "${each.key}-share-role"
}
