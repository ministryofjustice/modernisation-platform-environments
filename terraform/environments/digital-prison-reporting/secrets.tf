#### This file can be used to store secrets specific to the member account ####
resource "aws_secretsmanager_secret" "nomis" {
  name = "dpr/${local.project}-nomis-source-secrets"
}