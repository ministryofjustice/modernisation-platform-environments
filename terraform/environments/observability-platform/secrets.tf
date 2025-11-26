#tfsec:ignore:avd-aws-0098 CMK not required currently
resource "aws_secretsmanager_secret" "grafana_api_key" {
  #checkov:skip=CKV_AWS_149:CMK not required currently
  #checkov:skip=CKV2_AWS_57:Rotation of secrets not required currently

  name = "grafana/api-key"
}

#tfsec:ignore:avd-aws-0098 CMK not required currently
resource "aws_secretsmanager_secret" "github_app_id" {
  #checkov:skip=CKV_AWS_149:CMK not required currently
  #checkov:skip=CKV2_AWS_57:Rotation of secrets not required currently

  name = "grafana/data-sources/github-app-id"
}

#tfsec:ignore:avd-aws-0098 CMK not required currently
resource "aws_secretsmanager_secret" "github_app_installation_id" {
  #checkov:skip=CKV_AWS_149:CMK not required currently
  #checkov:skip=CKV2_AWS_57:Rotation of secrets not required currently

  name = "grafana/data-sources/github-app-installation-id"
}

#tfsec:ignore:avd-aws-0098 CMK not required currently
resource "aws_secretsmanager_secret" "github_app_private_key" {
  #checkov:skip=CKV_AWS_149:CMK not required currently
  #checkov:skip=CKV2_AWS_57:Rotation of secrets not required currently

  name = "grafana/data-sources/github-app-private-key"
}

#tfsec:ignore:avd-aws-0098 CMK not required currently
resource "aws_secretsmanager_secret" "slack_token" {
  #checkov:skip=CKV_AWS_149:CMK not required currently
  #checkov:skip=CKV2_AWS_57:Rotation of secrets not required currently

  name = "grafana/notifications/slack-token"
}

#tfsec:ignore:avd-aws-0098 CMK not required currently
resource "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  #checkov:skip=CKV_AWS_149:CMK not required currently
  #checkov:skip=CKV2_AWS_57:Rotation of secrets not required currently

  name = "grafana/notifications/pagerduty-integration-keys"
}

#tfsec:ignore:avd-aws-0098 CMK not required currently
resource "aws_secretsmanager_secret" "non_modernisation_platform_account_ids" {
  #checkov:skip=CKV_AWS_149:CMK not required currently
  #checkov:skip=CKV2_AWS_57:Rotation of secrets not required currently

  name = "observability-platform/non-modernisation-platform-account-ids"
}
