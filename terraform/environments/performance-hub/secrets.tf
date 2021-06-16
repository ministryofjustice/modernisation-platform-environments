# Get secret by name for database password
data "aws_secretsmanager_secret" "database_password" {
  name     = "database_password"
}

data "aws_secretsmanager_secret_version" "database_password" {
  secret_id = data.aws_secretsmanager_secret.database_password.arn
}
