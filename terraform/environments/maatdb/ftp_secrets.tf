# Secrets Manager Resource for the Lambda passwords. 
# This is required BEFORE the lambdas are built as the secrets are manually added & as such is always created.


# This secret manages the connection details for the SFTP endpoint.
# After the secret resource is created, update the value in the AWS console for each environment.
#
# The expected format is a flat JSON object:
#
# {
#   "HOST": "sftp.example.com",
#   "PORT": "22",
#   "USER": "username",
#   "PASSWORD": "password",
#   "REMOTEPATH": "/upload/"
# }
#
# Alternatively, the older array format is still supported:
#
# [
#   {
#     "name": "xerox-outbound",
#     "type": "remote-host",
#     "value": "sftp.example.com"
#   },
#   {
#     "name": "xerox-outbound",
#     "type": "remote-port",
#     "value": "22"
#   },
#   {
#     "name": "xerox-outbound",
#     "type": "remote-folder",
#     "value": "/upload/"
#   },
#   {
#     "name": "xerox-outbound",
#     "type": "username",
#     "value": "username"
#   },
#   {
#     "name": "xerox-outbound",
#     "type": "password",
#     "value": "password"
#   }
# ]

resource "aws_secretsmanager_secret" "ftp_jobs_secret" {
  #checkov:skip=CKV2_AWS_57:"This will be fixed at a later date"
  #checkov:skip=CKV_AWS_149:"To be added later."
  name = "${local.application_name}-${local.environment}-ftp-endpoint"
}

resource "aws_secretsmanager_secret_version" "ftp_jobs_secret_values" {
  secret_id = aws_secretsmanager_secret.ftp_jobs_secret.id
  secret_string = jsonencode({
    organisation_id = "CHANGE_ME_IN_THE_CONSOLE"
  })
}