data "aws_secretsmanager_secret" "ppud_slack_webhook" {
  name = module.ppud_slack_webhook.secret_id
}

data "aws_secretsmanager_secret_version" "ppud_slack_webhook" {
  secret_id = data.aws_secretsmanager_secret.ppud_slack_webhook.id
}
