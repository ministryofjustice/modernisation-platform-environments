
# API auth secret (this should be a key-value secret with an api-auth-token key)
resource "aws_secretsmanager_secret" "api_auth" {
  name = "data-platform-api-auth-token"
  tags = local.tags
}
