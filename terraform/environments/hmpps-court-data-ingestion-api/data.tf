#### This file can be used to store data specific to the member account ####

data "aws_secretsmanager_secret_version" "cloud_platform_account_id" {
  secret_id = aws_secretsmanager_secret.cloud_platform_account_id.id
}

data "aws_secretsmanager_secret_version" "auth_token" {
  secret_id = aws_secretsmanager_secret.ingestion_api_auth_token.id
}
