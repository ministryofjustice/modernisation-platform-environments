resource "aws_secretsmanager_secret" "soa_sandbox_secrets" {
  name        = "soasandbox-password"
  description = "SOA Weblogic,EM Console for user weblogic, RDS Database Password for SOAPDB admin, PUI and other passwords in Key values"
}

resource "aws_secretsmanager_secret_version" "sandbox_ccms_soa_secrets_version" {
  secret_id = aws_secretsmanager_secret.soa_sandbox_secrets.id

  secret_string = jsonencode({
    slack_channel_webhook           = "",
    slack_channel_webhook_guardduty = "",
    "ccms/soasandbox/password"         = "",
    "ccms/soasandbox/xxsoa/ds/password" = "",
    "ccms/soasandbox/ebs/ds/password"  = "",
    "ccms/soasandbox/ebs/sms/ds/password" = "",
    "ccms/soasandbox/pui/user/password" = "",
    "ccms/soasandbox/ebs/user/password" = "",
    "ccms/soasandbox/deploy-github-ssh-key" = "",
    "ccms/soasandbox/java/trust-store/password" = ""
  })

  # lifecycle {
  #   ignore_changes = [
  #     secret_string
  #   ]
  # }
}

data "aws_secretsmanager_secret_version" "soa_password" {
  secret_id = aws_secretsmanager_secret.soa_sandbox_secrets.id
}

# resource "aws_secretsmanager_secret" "xxsoa_sandbox_ds_password" {
#   name        = "ccms/soasandbox/xxsoa/ds/password"
#   description = "EDRMS TDS XXSOA Data Source Password User XXEDRMS - Comes from different account EDRMS"
# }

# data "aws_secretsmanager_secret_version" "xxsoa_ds_password" {
#   secret_id = aws_secretsmanager_secret.xxsoa_sandbox_ds_password.id
# }

# resource "aws_secretsmanager_secret" "ebs_sandbox_ds_password" {
#   name        = "ccms/soasandbox/ebs/ds/password"
#   description = "EBS Data Source Password for APPS User"
# }

# resource "aws_secretsmanager_secret" "ebssms_sandbox_ds_password" {
#   name        = "ccms/soasandbox/ebs/sms/ds/password"
#   description = "EBS SMS Data Source Password CWA APPS User"
# }

# resource "aws_secretsmanager_secret" "pui_sandbox_user_password" {
#   name        = "ccms/soasandbox/pui/user/password"
#   description = "PUI_USER Password for security realm"
# }

# resource "aws_secretsmanager_secret" "ebs_user_password" {
#   name        = "ccms/soasandbox/ebs/user/password"
#   description = "EBS DB User ebs_soa_super_user Password for security realm"
# }

# resource "aws_secretsmanager_secret" "soa_deploy_ssh_key" {
#   name        = "ccms/soasandbox/deploy-github-ssh-key"
#   description = "Github SSH Deploy Key"
# }

# resource "aws_secretsmanager_secret" "trust_store_password" {
#   name        = "ccms/soasandbox/java/trust-store/password"
#   description = "Password for the Java Trust Store used by SOA"
# }

# data "aws_secretsmanager_secret_version" "trust_store_password" {
#   secret_id = aws_secretsmanager_secret.trust_store_password.id
# }

# Slack Channel ID for Alerts
# resource "aws_secretsmanager_secret" "slack_channel_id" {
#   name        = "guardduty_slack_channel_id"
#   description = "Slack Channel ID for GuardDuty Alerts"
# }

# data "aws_secretsmanager_secret_version" "slack_channel_id" {
#   secret_id = aws_secretsmanager_secret.slack_channel_id.id
# }

##########################################################
# Slack Webhook Secret for CCMS SOA EDN Quiesced Alerts
##########################################################
# resource "aws_secretsmanager_secret" "ccms_soa_quiesced_secrets" {
#   name        = "${local.application_name}-edn-quiesced-alerts"
#   description = "Slack Webhook Secret for CCMS SOA EDN Quiesced Lambda Alerts"

#   tags = merge(local.tags, {
#     Name = "${local.application_name}-edn-quiesced-alerts"
#   })
# }



