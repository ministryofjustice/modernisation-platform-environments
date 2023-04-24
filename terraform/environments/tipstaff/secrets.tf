#### This file can be used to store secrets specific to the member account ####
data "aws_secretsmanager_secret" "tipstaff_dev_db_secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:913862848426:secret:tipstaff-dev-db-secrets-8Qc18f"
}

data "aws_secretsmanager_secret" "tactical_products_db_secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:913862848426:secret:tactical-products-db-secrets-ox3sNi"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.tipstaff_dev_db_secrets.id
}

data "aws_secretsmanager_secret_version" "dms_source_credentials" {
  secret_id = data.aws_secretsmanager_secret.tactical_products_db_secrets.id
}
