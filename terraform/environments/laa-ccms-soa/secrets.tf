############################################################
# SOA RDS + WebLogic Password
############################################################
resource "aws_secretsmanager_secret" "soa_password" {
  name        = "ccms/soa/password"
  description = "Shared password for SOA WebLogic admin user and SOADB admin user"
}

data "aws_secretsmanager_secret_version" "soa_password" {
  secret_id = aws_secretsmanager_secret.soa_password.id
}

############################################################
# XXSOA – EDRMS Data Source Password
############################################################
resource "aws_secretsmanager_secret" "xxsoa_ds_password" {
  name        = "ccms/soa/xxsoa/ds/password"
  description = "XXSOA datasource password for XXEDRMS user"
}

data "aws_secretsmanager_secret_version" "xxsoa_ds_password" {
  secret_id = aws_secretsmanager_secret.xxsoa_ds_password.id
}

############################################################
# EBS Datasource Passwords
############################################################
resource "aws_secretsmanager_secret" "ebs_ds_password" {
  name        = "ccms/soa/ebs/ds/password"
  description = "EBS APPS user datasource password"
}

data "aws_secretsmanager_secret_version" "ebs_ds_password" {
  secret_id = aws_secretsmanager_secret.ebs_ds_password.id
}

resource "aws_secretsmanager_secret" "ebssms_ds_password" {
  name        = "ccms/soa/ebs/sms/ds/password"
  description = "EBS SMS APPS user datasource password"
}

data "aws_secretsmanager_secret_version" "ebssms_ds_password" {
  secret_id = aws_secretsmanager_secret.ebssms_ds_password.id
}

############################################################
# Security Realm Passwords
############################################################
resource "aws_secretsmanager_secret" "pui_user_password" {
  name        = "ccms/soa/pui/user/password"
  description = "PUI_USER password for WebLogic security realm"
}

data "aws_secretsmanager_secret_version" "pui_user_password" {
  secret_id = aws_secretsmanager_secret.pui_user_password.id
}

resource "aws_secretsmanager_secret" "ebs_user_password" {
  name        = "ccms/soa/ebs/user/password"
  description = "ebs_soa_super_user password for WebLogic security realm"
}

data "aws_secretsmanager_secret_version" "ebs_user_password" {
  secret_id = aws_secretsmanager_secret.ebs_user_password.id
}

############################################################
# GitHub Deploy SSH Key
############################################################
resource "aws_secretsmanager_secret" "soa_deploy_ssh_key" {
  name        = "ccms/soa/deploy-github-ssh-key"
  description = "SSH deploy key for GitHub"
}

data "aws_secretsmanager_secret_version" "soa_deploy_ssh_key" {
  secret_id = aws_secretsmanager_secret.soa_deploy_ssh_key.id
}

############################################################
# Java Trust Store Password
############################################################
resource "aws_secretsmanager_secret" "trust_store_password" {
  name        = "ccms/soa/java/trust-store/password"
  description = "Java trust store password for SOA"
}

data "aws_secretsmanager_secret_version" "trust_store_password" {
  secret_id = aws_secretsmanager_secret.trust_store_password.id
}

############################################################
# Slack GuardDuty Channel ID
############################################################
resource "aws_secretsmanager_secret" "slack_channel_id" {
  name        = "guardduty_slack_channel_id"
  description = "Slack channel ID for GuardDuty alerts"
}

data "aws_secretsmanager_secret_version" "slack_channel_id" {
  secret_id = aws_secretsmanager_secret.slack_channel_id.id
}

############################################################
# Slack Webhook for SOA EDN Quiesced Alerts
############################################################
resource "aws_secretsmanager_secret" "ccms_soa_quiesced_secrets" {
  name        = "${local.application_name}-edn-quiesced-alerts"
  description = "Slack webhook for CCMS SOA EDN Quiesced Lambda Alerts"

  tags = merge(local.tags, {
    Name = "${local.application_name}-edn-quiesced-alerts"
  })
}

resource "aws_secretsmanager_secret_version" "ccms_soa_quiesced_secrets_version" {
  secret_id = aws_secretsmanager_secret.ccms_soa_quiesced_secrets.id

  secret_string = jsonencode({
    slack_channel_webhook = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

############################################################
# OEM Agent Credentials
############################################################
data "aws_secretsmanager_secret" "oem_agent_credentials" {
  name = "ccms/soa/oem_agent_credentials"
}

data "aws_secretsmanager_secret_version" "oem_agent_credentials" {
  secret_id = data.aws_secretsmanager_secret.oem_agent_credentials.id
}
