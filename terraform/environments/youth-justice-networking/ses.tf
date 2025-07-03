resource "aws_ses_domain_identity" "yjb" {
  domain = "yjb.gov.uk"
}

resource "aws_ses_domain_dkim" "yjb" {
  domain = aws_ses_domain_identity.yjb.domain
}

resource "aws_iam_user" "ses_smtp_user" {
  name = "ses-smtp-user"
}

resource "aws_iam_policy" "ses_smtp_send_policy" {
  name        = "ses-smtp-send-policy"
  description = "Allow sending email via SES for yjb.gov.uk"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ses:SendRawEmail"
        Resource = aws_ses_domain_identity.yjb.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "ses_smtp_user_attach" {
  user       = aws_iam_user.ses_smtp_user.name
  policy_arn = aws_iam_policy.ses_smtp_send_policy.arn
}

resource "aws_iam_access_key" "ses_smtp_user" {
  user = aws_iam_user.ses_smtp_user.name
}

resource "aws_secretsmanager_secret" "ses_smtp" {
  name = "ses-smtp-credentials"
}

resource "aws_secretsmanager_secret_version" "ses_smtp_version" {
  secret_id = aws_secretsmanager_secret.ses_smtp.id
  secret_string = jsonencode({
    smtp_username = aws_iam_access_key.ses_smtp_user.id
    smtp_password = aws_iam_access_key.ses_smtp_user.ses_smtp_password_v4
  })
}

output "ses_verification_token" {
  value = aws_ses_domain_identity.yjb.verification_token
}

output "ses_dkim_tokens" {
  value = aws_ses_domain_dkim.yjb.dkim_tokens
}