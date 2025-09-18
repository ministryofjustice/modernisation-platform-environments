# Secrets Manager Resource for the Lambda passwords. 
# This is required BEFORE the lambdas are built as the secrets are manually added & as such is always created.


# This secret manages the details of the endpoints such as server names and remote folders
# It will have:

# 1. The name of the job. This will match the value of ftp_job.job_name in the ftp_lambda.tf file
# 2. The value type (host_address or remote_folder)
# 3. The secret value

# For example:

# [
#   {
#     "name": "xerox-outbound",
#     "type": "remote-host",
#     "value": "sftp.example.com" or IP address
#   },
#   {
#     "name": "xerox-outbound",
#     "type": "remote-port",
#     "value": "22"
#   },
#   {
#     "name": "xerox-outbound",
#     "type": "remote-folder",
#     "value": "/incoming/"
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

data "aws_secretsmanager_secret_version" "ftp_jobs_secret_version" {
  count     = local.build_ftp ? 1 : 0
  secret_id = aws_secretsmanager_secret.ftp_jobs_secret.id
}