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
