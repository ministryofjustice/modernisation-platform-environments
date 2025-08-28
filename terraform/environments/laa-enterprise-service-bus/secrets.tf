#####################################################################################
### Secrets used for CWA Extract Lambda Functions ###
#####################################################################################

resource "aws_secretsmanager_secret" "cwa_procedures_config" {
  name = "cwa-extract-lambda-procedures-config-${local.environment}"
}

resource "aws_secretsmanager_secret" "cwa_db_secret" {
  name = "cwa-extract-lambda-db-secret-${local.environment}"
}

resource "aws_secretsmanager_secret" "cwa_table_name_secret" {
  name = "cwa-file-transfer-table-lambda-secret-${local.environment}"
}

#####################################################################################
### Secrets used for CCMS Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "ccms_db_mp_credentials" {
  name = "ccms-db-mp-credentials-${local.environment}"
}

resource "aws_secretsmanager_secret" "ccms_procedures_config" {
  name = "ccms-provider-lambda-procedures-config-${local.environment}"
}

#####################################################################################
### Secrets used for MAAT Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "maat_db_mp_credentials" {
  name = "maat-db-mp-credentials-${local.environment}"
}

resource "aws_secretsmanager_secret" "maat_procedures_config" {
  name = "maat-provider-lambda-procedures-config-${local.environment}"
}

#####################################################################################
### Secrets used for CCR Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "ccr_db_mp_credentials" {
  name = "ccr-db-mp-credentials-${local.environment}"
}

resource "aws_secretsmanager_secret" "ccr_procedures_config" {
  name = "ccr-provider-lambda-procedures-config-${local.environment}"
}

#####################################################################################
### Secrets used for CCLF Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "cclf_db_mp_credentials" {
  name = "cclf-db-mp-credentials-${local.environment}"
}

resource "aws_secretsmanager_secret" "cclf_procedures_config" {
  name = "cclf-provider-lambda-procedures-config-${local.environment}"
}