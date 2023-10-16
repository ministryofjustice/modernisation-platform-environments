
# API auth secret (this should be a key-value secret with an api-auth-token key)
resource "random_password" "auth_token" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = true
}

resource "aws_secretsmanager_secret" "api_auth" {
  name = "data-platform-api-auth-token"
}

resource "aws_secretsmanager_secret_version" "api_auth" {
  secret_id     = aws_secretsmanager_secret.api_auth.id
  secret_string = random_password.auth_token.result
}
