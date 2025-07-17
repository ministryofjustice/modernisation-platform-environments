# This creates the secrets manager & data items required to hold end-user secrets for the sftp transfer service

# The secret values are:


# 1. The name of the job. This is "xhibit-inbound"
# 2. The value type (public_key or source_cidr)
# 3. The secret value

# Add all inbound CIDRs to filter for as required

# For example:

# [
#   {
#     "name": "xhibit-inbound",
#     "type": "username",
#     "value": "example_user_name""
#   },
#   {
#     "name": "xhibit-inbound",
#     "type": "public_key",
#     "value": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3dummykeyEXAMPLEonly1234567890abcdefghijklmnopqrstuvwxYzDUMMYKEYexampleFORtestingONLY user@example.com"
#   },
#   {
#     "name": "xhibit-inbound",
#     "type": "source_cidr_1",
#     "value": "1.1.1.1/32"
#   },
#   {
#     "name": "xhibit-inbound",
#     "type": "source_cidr_2",
#     "value": "2.2.2.2/32"
#   },
# ]

resource "aws_secretsmanager_secret" "transfer_service_secret" {
  #checkov:skip=CKV2_AWS_57:"This will be fixed at a later date"
  #checkov:skip=CKV_AWS_149:"To be added later."
  name = "${local.application_name}-${local.environment}-transfer-service-secret"
}

resource "aws_secretsmanager_secret_version" "transfer_service_secret_values" {
  secret_id = aws_secretsmanager_secret.transfer_service_secret.id
  secret_string = jsonencode({
    tempvalues = "CHANGE_ME_IN_THE_CONSOLE"
  })
}

data "aws_secretsmanager_secret_version" "transfer_service_secret_version" {
  count     = local.build_transfer ? 1 : 0
  secret_id = aws_secretsmanager_secret.transfer_service_secret.id
}