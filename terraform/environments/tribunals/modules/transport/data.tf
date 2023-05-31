
data "aws_db_instance" "database" {
  db_instance_identifier = "tribunals-db-dev" #var.db_instance_identifier
}

data "aws_secretsmanager_secret" "rds-secrets" {
  arn = var.rds_secret_arn
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds-secrets.id
}
