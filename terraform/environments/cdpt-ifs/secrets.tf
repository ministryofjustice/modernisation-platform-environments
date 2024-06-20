resource "aws_secretsmanager_secret" "db_pass" {
  name = "db_password"
}

resource "random_password" "password_long" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret_version" "db_pass" {
  secret_id     = aws_secretsmanager_secret.db_pass.id
  secret_string = random_password.password_long.result
}
