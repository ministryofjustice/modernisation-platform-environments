#### This file can be used to store secrets specific to the member account ####

resource "aws_secretsmanager_secret" "edrms_secret" {
  name        = "edrms-secret"
  description = "EDRMS secret for CCMS EDRMS application"
}

# resource "aws_secretsmanager_secret_version" "edrms_secret_version" {
#   secret_id = aws_secretsmanager_secret.edrms_secret.id
#   secret_string = jsonencode({
#      "ccms/edrms/datasource" = "secret1"
#      "alerts_slack_channel_id" = "secret2"
#   })
# }

data "aws_secretsmanager_secret_version" "edrms_secret_version" {
  secret_id = aws_secretsmanager_secret.edrms_secret.id
}

/*
  The combined secret above (resource: aws_secretsmanager_secret.edrms_secret
  with version aws_secretsmanager_secret_version.edrms_secret_version) contains
  both values:
    - ccms/edrms/datasource
    - alerts_slack_channel_id

  Individual per-key secret resources were removed so the code reads both
  keys from the single combined secret via locals (see locals.tf).
*/