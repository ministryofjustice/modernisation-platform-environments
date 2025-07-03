resource "aws_secretsmanager_secret" "soa_password" {
  name        = "ccms/soa/password"
  description = "SOA Weblogic EM Console for user weblogic and RDS Database Password for SOAPDB admin" #--The same password shared between the SOA DB
}                                                                                                      #  and weblogic. Don't like that. Revisit. AW

data "aws_secretsmanager_secret_version" "soa_password" {
  secret_id = aws_secretsmanager_secret.soa_password.id
}

resource "aws_secretsmanager_secret" "xxsoa_ds_password" {
  name        = "ccms/soa/xxsoa/ds/password"
  description = "EDRMS TDS XXSOA Data Source Password User XXEDRMS - Comes from different account EDRMS"
}

data "aws_secretsmanager_secret_version" "xxsoa_ds_password" {
  secret_id = aws_secretsmanager_secret.xxsoa_ds_password.id
}

resource "aws_secretsmanager_secret" "ebs_ds_password" {
  name        = "ccms/soa/ebs/ds/password"
  description = "EBS Data Source Password for APPS User"
}

resource "aws_secretsmanager_secret" "ebssms_ds_password" {
  name        = "ccms/soa/ebs/sms/ds/password"
  description = "EBS SMS Data Source Password CWA APPS User"
}

resource "aws_secretsmanager_secret" "pui_user_password" {
  name        = "ccms/soa/pui/user/password"
  description = "PUI_USER Password for security realm"
}

resource "aws_secretsmanager_secret" "ebs_user_password" {
  name        = "ccms/soa/ebs/user/password"
  description = "EBS DB User ebs_soa_super_user Password for security realm"
}

resource "aws_secretsmanager_secret" "soa_deploy_ssh_key" {
  name        = "ccms/soa/deploy-github-ssh-key"
  description = "Github SSH Deploy Key"
}

resource "aws_secretsmanager_secret" "alerting_webhook_url" {
  name        = "ccms/soa/alerting_webhook_url"
  description = "Alerting Slack Webook URL"
}

data "aws_secretsmanager_secret_version" "alerting_webhook_url" {
  secret_id = aws_secretsmanager_secret.alerting_webhook_url.id
}
