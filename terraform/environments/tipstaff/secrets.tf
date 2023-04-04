#### This file can be used to store secrets specific to the member account ####
data "aws_secretsmanager_secret" "tipstaff-dev-db-secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:913862848426:secret:tipstaff-dev-db-secrets-8Qc18f"
}

data "aws_secretsmanager_secret" "tipstaff_public_key" {
  arn = "arn:aws:secretsmanager:eu-west-2:913862848426:secret:tipstaff_public_key-B1zpNE"
}

data "aws_secretsmanager_secret_version" "public_key" {
  secret_id = data.aws_secretsmanager_secret.tipstaff_public_key.id
}

data "aws_secretsmanager_secret_version" "db_username" {
  secret_id = data.aws_secretsmanager_secret.tipstaff-dev-db-secrets.id
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.tipstaff-dev-db-secrets.id
}

data "aws_secretsmanager_secret" "github_oauth_token" {
  arn = "arn:aws:secretsmanager:eu-west-2:913862848426:secret:Github_Oauth_Token-kApArG"
}

data "aws_secretsmanager_secret_version" "oauth_token" {
  secret_id = data.aws_secretsmanager_secret.github_oauth_token.id
}
