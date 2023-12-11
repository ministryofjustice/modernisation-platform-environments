#### This file can be used to store secrets specific to the member account ####

resource "aws_secretsmanager_secret" "chaps_secret" {
  name        = "chaps_secret"
  description = "Simple secret created through Terraform"
}

resource "random_password" "password" {
	length = 10
}

resource "aws_secretsmanager_secret_version" "chaps_secret" {
  secret_id     = aws_secretsmanager_secret.chaps_secret.id
  secret_string = random_password.password.result
}
