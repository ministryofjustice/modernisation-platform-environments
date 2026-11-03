/*
  Airflow 3 sends task failure/retry emails through SmtpNotifier, which reads the
  `smtp_default` Airflow connection (not the [smtp] config section used by Airflow 2).
  The MWAA secrets backend resolves connections from Secrets Manager under
  `airflow/connections/`, so the connection is stored here, built from the existing
  `mwaa-ses` IAM user's SES SMTP credentials.
*/

resource "aws_secretsmanager_secret" "airflow_smtp_default" {
  #checkov:skip=CKV2_AWS_57:SES SMTP password is derived from the IAM user access key; rotate by rotating the key

  name        = "airflow/connections/smtp_default"
  description = "Airflow SMTP connection for Amazon SES (used by Airflow 3 email notifications)"
  kms_key_id  = data.aws_kms_key.common_secrets_manager_kms.arn

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "airflow_smtp_default" {
  secret_id = aws_secretsmanager_secret.airflow_smtp_default.id
  secret_string = jsonencode({
    conn_type = "smtp"
    host      = "email-smtp.${data.aws_region.current.region}.amazonaws.com"
    port      = 587
    login     = module.mwaa_ses_iam_user.access_key_id
    password  = module.mwaa_ses_iam_user.access_key_ses_smtp_password_v4
    extra = {
      from_email  = "noreply@${local.environment_configuration.route53_zone}"
      disable_ssl = true  # port 587 uses STARTTLS, not implicit SSL
      disable_tls = false # keep STARTTLS on
      timeout     = 30
      retry_limit = 3
    }
  })
}