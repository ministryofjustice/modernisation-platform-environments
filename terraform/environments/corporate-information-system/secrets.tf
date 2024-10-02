#### This file can be used to store secrets specific to the member account ####
resource "random_password" "cis_db_secret" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_secret" {
  name        = "${local.application_name_short}/app/db-master-password"
  description = "This secret has a dynamically generated password."
}

resource "aws_secretsmanager_secret_version" "cloudfront" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = random_password.cis_db_secret.result
}