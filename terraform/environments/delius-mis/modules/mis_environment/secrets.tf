#### This file can be used to store secrets specific to the member account ####
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "ad_username" {
  #checkov:skip=CKV_AWS_149 "ignore"
  name                    = "${var.env_name}-legacy-ad-username"
  recovery_window_in_days = 0

  tags = var.tags
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "ad_password" {
  #checkov:skip=CKV_AWS_149 "ignore"
  name                    = "${var.env_name}-legacy-ad-password"
  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret" "boe_config" {
  name = "${var.app_name}-${var.env_name}-sap-boe-config"

  description = "Config secrets for SAP BIP reporting system"
  kms_key_id  = var.account_config.kms_keys["general_shared"]

  tags = var.tags
}

resource "aws_secretsmanager_secret" "boe_passwords" {
  name = "${var.app_name}-${var.env_name}-sap-boe-passwords"

  description = "Passwords for SAP BIP reporting system"
  kms_key_id  = var.account_config.kms_keys["general_shared"]

  tags = var.tags
}

resource "aws_secretsmanager_secret" "dis_config" {
  name = "${var.app_name}-${var.env_name}-sap-dis-config"

  description = "Config secrets for SAP BODS DIS ETL system"
  kms_key_id  = var.account_config.kms_keys["general_shared"]

  tags = var.tags
}

resource "aws_secretsmanager_secret" "dis_passwords" {
  name = "${var.app_name}-${var.env_name}-sap-dis-passwords"

  description = "Passwords for SAP BODS DIS ETL system"
  kms_key_id  = var.account_config.kms_keys["general_shared"]

  tags = var.tags
}
