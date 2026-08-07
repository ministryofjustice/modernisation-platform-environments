resource "aws_secretsmanager_secret" "database_password" {
  name        = "username"
  description = "Database username"
}

resource "aws_secretsmanager_secret" "client_id" {
  name        = "client_id"
  description = "client"
}