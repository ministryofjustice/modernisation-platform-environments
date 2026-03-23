#### This file can be used to store secrets specific to the member account ####
resource "aws_secretsmanager_secret" "circleci" {
  name        = "test-oidc-secret"
}