data "aws_secretsmanager_secret" "ad_connector_password" {
  count = local.deploy_workspaces ? 1 : 0
  name  = local.application_data.accounts[local.environment].ad_connector_secret_name
}

data "aws_secretsmanager_secret_version" "ad_connector_password" {
  count     = local.deploy_workspaces ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.ad_connector_password[0].id
}
