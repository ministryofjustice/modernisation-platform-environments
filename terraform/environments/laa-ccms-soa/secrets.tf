resource "aws_secretsmanager_secret" "soa_password" {
  name        = "ccms/soa/password"
  description = "SOA Weblogic EM Console and Database Password" #--Is the same password shared between two services? Don't like that. Revisit. AW
}

data "aws_secretsmanager_secret_version" "soa_password" {
  secret_id = aws_secretsmanager_secret.soa_password.id
}

resource "aws_secretsmanager_secret" "xxsoa_ds_password" {
  name        = "ccms/soa/xxsoa/ds/password"
  description = "TDS XXSOA Data Source Password"
}

data "aws_secretsmanager_secret_version" "xxsoa_ds_password" {
  secret_id = aws_secretsmanager_secret.xxsoa_ds_password.id
}

resource "aws_secretsmanager_secret" "ebs_ds_password" {
  name        = "ccms/soa/ebs/ds/password"
  description = "EBS Data Source Password"
}

resource "aws_secretsmanager_secret" "ebssms_ds_password" {
  name        = "ccms/soa/ebs/sms/ds/password"
  description = "EBS SMS Data Source Password"
}

resource "aws_secretsmanager_secret" "pui_user_password" {
  name        = "ccms/soa/pui/user/password"
  description = "PUI User Password"
}

resource "aws_secretsmanager_secret" "ebs_user_password" {
  name        = "ccms/soa/ebs/user/password"
  description = "EBS User Password"
}

resource "aws_secretsmanager_secret" "soa_deploy_ssh_key" {
  name        = "ccms/soa/deploy-github-ssh-key"
  description = "Github SSH Deploy Key"
}
