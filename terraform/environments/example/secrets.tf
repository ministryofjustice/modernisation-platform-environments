resource "aws_secretsmanager_secret" "cooker_client_id" {
  provider    = aws.shared-configuration-access
  name        = "platforms/client_id"
  description = "test"
}