# Secrets Manager Resource for the Lambda passwords. 
# This is required BEFORE the lambdas are built as the secrets are manually added & as such is always created.


# This secret manages all connection details for the SFTP endpoint.
# After the Terraform resource is created, update the secret value in the AWS console for each environment.
#
# Required format — flat JSON:
#
# {
#   "HOST": "sftp.example.com",
#   "USER": "username",
#   "PASSWORD": "password",
#   "SLACK_WEBHOOK": "https://hooks.slack.com/services/..."
# }
#
# PORT and REMOTEPATH are configured as Lambda environment variables, not in the secret.

resource "aws_secretsmanager_secret" "ftp_jobs_secret" {
  #checkov:skip=CKV2_AWS_57:"This will be fixed at a later date"
  #checkov:skip=CKV_AWS_149:"To be added later."
  name = "${local.application_name}-${local.environment}-ftp-endpoint"
}

resource "aws_secretsmanager_secret_version" "ftp_jobs_secret_values" {
  secret_id = aws_secretsmanager_secret.ftp_jobs_secret.id
  secret_string = jsonencode({
    HOST         = "",
    USER         = "",
    PASSWORD     = "",
    SLACK_WEBHOOK = ""
  })
  lifecycle {
    # Prevent Terraform from overwriting secret values that are managed manually in the AWS console.
    ignore_changes = [secret_string]
  }
}