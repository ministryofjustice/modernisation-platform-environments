data "aws_secretsmanager_secret" "ppud_slack_webhook" {
  count = local.is-test ? 0 : 1

  name = module.ppud_slack_webhook[0].secret_id
}

data "aws_secretsmanager_secret_version" "ppud_slack_webhook" {
  count = local.is-test ? 0 : 1

  secret_id = data.aws_secretsmanager_secret.ppud_slack_webhook[0].id
}
