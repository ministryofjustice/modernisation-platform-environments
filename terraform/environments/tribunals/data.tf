#### This file can be used to store data specific to the member account ####
data "aws_db_instance" "database" {
  db_instance_identifier = "tf-tribunals-dev"
}

data "aws_secretsmanager_secret" "rds-secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:263310006819:secret:tribunals-db-dev-credentials-WIKA7c"
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds-secrets.id
}

data "aws_secretsmanager_secret" "source-db-secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:263310006819:secret:tribunals-source-db-credentials-dev-BHvvLl"
}

data "aws_secretsmanager_secret_version" "source-db" {
  secret_id = data.aws_secretsmanager_secret.source-db-secrets.id
}