
data "aws_db_instance" "database" {
  db_instance_identifier = var.db_instance_identifier
}

data "aws_secretsmanager_secret" "rds-secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:207640118376:secret:tf-tribunals-dev-credentials-3Qvv1c"
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds-secrets.id
}
