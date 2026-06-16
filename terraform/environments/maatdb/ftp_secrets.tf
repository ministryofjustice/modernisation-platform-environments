# Secrets Manager Resource for the Lambda passwords. 
# This is required BEFORE the lambdas are built as the secrets are manually added & as such is always created.


# This secret manages all connection details for the SFTP endpoint.
# After the Terraform resource is created, update the secret value in the AWS console for each environment.
#
# Required format — flat JSON:
#
# {
#   "HOST": "sftp.example.com",
#   "PORT": "22",
#   "USER": "username",
#   "PASSWORD": "password",
#   "REMOTEPATH": "/upload/"
# }

resource "aws_secretsmanager_secret" "ftp_jobs_secret" {
  #checkov:skip=CKV2_AWS_57:"This will be fixed at a later date"
  #checkov:skip=CKV_AWS_149:"To be added later."
  name = "${local.application_name}-${local.environment}-ftp-endpoint"
}

resource "aws_secretsmanager_secret_version" "ftp_jobs_secret_values" {
  secret_id = aws_secretsmanager_secret.ftp_jobs_secret.id
  secret_string = jsonencode({
    HOST       = "",
    PORT       = "",
    USER       = "",
    PASSWORD   = "",
    REMOTEPATH = ""
  })
  lifecycle {
    # Prevent Terraform from overwriting secret values that are managed manually in the AWS console.
    ignore_changes = [secret_string]
  }
}

data "aws_secretsmanager_secret_version" "ftp_jobs_secret_version" {
  count      = local.build_ftp ? 1 : 0
  secret_id  = aws_secretsmanager_secret.ftp_jobs_secret.id
  depends_on = [aws_secretsmanager_secret_version.ftp_jobs_secret_values]
}