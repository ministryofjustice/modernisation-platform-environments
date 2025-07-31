#####################################################################################
### Secrets used for CWA Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "cwa_procedures_config" {
  name = "cwa-extract-lambda-procedures-config-${local.environment}"
}

resource "aws_secretsmanager_secret" "cwa_db_secret" {
  name = "cwa-extract-lambda-db-secret-${local.environment}"
}

resource "aws_secretsmanager_secret" "cwa_db_ssh_key" {
  name = "cwa-extract-lambda-db-ssh-key-secret-${local.environment}"
}
