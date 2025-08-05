# This creates the secrets manager & data items required to hold end-user secrets for the sftp transfer service

# The secret values are:


# 1. The type - this will be user"
# 2. The secret values  - one of each username, folder, public_key and one or more source_cidrs.

# For example:

# [
#   {
#     "type": "user",
#     "username": "example_user_name_1",
#     "public_key": "ssh-ed25519 AAAAC3Nz...",
#     "bucket_name": "xhibit-inbound-user-1",
#     "folder": "user1/",
#     "ingress_cidrs": ["1.1.1.1/32"]
#   },
#   {
#     "type": "user",
#     "username": "example_user_name_2",
#     "public_key": "ssh-rsa AAAAB3Nza...",
#     "bucket_name": "xhibit-inbound-user-2",
#     "folder": "user2/"
#     "ingress_cidrs": ["2.2.2.2/32", "3.3.3.3/32"]
#   }
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