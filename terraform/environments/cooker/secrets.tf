#### This file can be used to store secrets specific to the member account ####
resource "aws_secretsmanager_secret" "database_password" {
  name        = "username"
  description = "Database username"
}