
# API auth secret (this should be a key-value secret with an api-auth-token key)
resource "aws_secretsmanager_secret" "api_auth" {
  name = "data-platform-api-auth-token"
  tags = local.tags
}

data "aws_secretsmanager_secret_version" "api_auth" {
  secret_id = aws_secretsmanager_secret.api_auth.id
}

# openmeta jwt for api
resource "aws_secretsmanager_secret" "openmetadata" {
  name = "data-platform-openmetadata-token"
  tags = local.tags
}
