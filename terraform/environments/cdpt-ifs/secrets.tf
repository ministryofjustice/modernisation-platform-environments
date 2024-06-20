resource "aws_secretsmanager_secret" "db_password" {
  name = "database_password"
}

resource "random_password" "password_long" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret_version" "dev_db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.password_long.result
}
