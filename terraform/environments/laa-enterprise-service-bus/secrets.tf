#####################################################################################
### Secrets used for CWA Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "cwa_procedures_config" {
  name = "${local.application_name_short}-${local.environment}-procedures-config"
}

resource "aws_secretsmanager_secret" "cwa_db_secret" {
  name = "${local.application_name_short}-${local.environment}-db-secret"
}