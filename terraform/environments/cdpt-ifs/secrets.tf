resource "aws_secretsmanager_secret" "dbase_password" {
  name = "dbase_password"
}

resource "random_password" "password_long" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret_version" "dbase_password" {
  secret_id     = aws_secretsmanager_secret.dbase_password.id
  secret_string = random_password.password_long.result
}
