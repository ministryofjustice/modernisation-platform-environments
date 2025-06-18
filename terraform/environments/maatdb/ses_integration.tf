# SES SMTP Integration from MAATDB


# Get the Route 53 hosted zone for the domain
data "aws_route53_zone" "zone" {
  name         = local.hosted_zone
  private_zone = false
}

locals {

  # SES Specific Locals
  hosted_zone = local.application_data.accounts[local.environment].hosted_zone
  ses_domain = local.application_data.accounts[local.environment].ses_domain
   
}

resource "aws_iam_user" "smtp_user" {
  # checkov:skip=CKV_AWS_273:Required for SMTP
  count = local.build_ses ? 1 : 0
  name  = "${local.application_name}-smtp-user"
}

resource "aws_iam_access_key" "smtp_user_key" {
  count = local.build_ses ? 1 : 0
  user  = aws_iam_user.smtp_user[0].name
}

resource "aws_secretsmanager_secret" "smtp_access_key_secret" {
  count = local.build_ses ? 1 : 0
  name  = "ses-smtp-user-access-key"
}

resource "aws_secretsmanager_secret_version" "smtp_access_key_secret_version" {
  count      = local.build_ses ? 1 : 0
  secret_id  = aws_secretsmanager_secret.smtp_access_key_secret[0].id
  secret_string = jsonencode({
    IAM_ACCESS_KEY_ID     = aws_iam_access_key.smtp_user_key[0].id
    IAM_SECRET_ACCESS_KEY = aws_iam_access_key.smtp_user_key[0].secret
  })
}

resource "aws_iam_user_policy" "smtp_user_policy" {
  # checkov:skip=CKV_AWS_40:Policy attached to User due to Modernisation Platform restrictions
  # checkov:skip=CKV_AWS_290:Policy does not deal with write access
  count  = local.build_ses ? 1 : 0
  name   = "${local.application_name}-SMTPUserPolicy"
  user   = aws_iam_user.smtp_user[0].name
  policy = data.aws_iam_policy_document.smtp_user_policy.json
}

data "aws_iam_policy_document" "smtp_user_policy" {
  statement {
    effect = "Allow"
    actions = ["ses:SendRawEmail"]
    resources = length(aws_ses_domain_identity.domain) > 0 ? [aws_ses_domain_identity.domain[0].arn] : []
  }
}

# These resources generate the SMTP password required to access SES SMTP.

resource "aws_secretsmanager_secret" "smtp_credentials" {
  count = local.build_ses ? 1 : 0
  name  = "ses-smtp-credentials"
}

resource "aws_secretsmanager_secret_version" "smtp_secret_version" {
  count        = local.build_ses ? 1 : 0
  secret_id    = aws_secretsmanager_secret.smtp_credentials[0].id

  secret_string = jsonencode({
    SMTP_USERNAME = aws_iam_access_key.smtp_user_key[0].id
    SMTP_PASSWORD = aws_iam_access_key.smtp_user_key[0].ses_smtp_password_v4
  })
}


#  SES & Route53 resources

# SES domain identity
resource "aws_ses_domain_identity" "domain" {
  count  = local.build_ses ? 1 : 0
  domain = local.ses_domain
}

# Add SES verification TXT record to Route 53
resource "aws_route53_record" "verification" {
  count   = local.build_ses ? 1 : 0
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "_amazonses.${local.ses_domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.domain[0].verification_token]
}

# Enable DKIM
resource "aws_ses_domain_dkim" "dkim" {
  count  = local.build_ses ? 1 : 0
  domain = aws_ses_domain_identity.domain[0].domain
}

# Add DKIM CNAME records to Route 53
resource "aws_route53_record" "dkim" {
  count   = local.build_ses ? 3 : 0
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${aws_ses_domain_dkim.dkim[0].dkim_tokens[count.index]}._domainkey.${local.ses_domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.dkim[0].dkim_tokens[count.index]}.dkim.amazonses.com"]
}


# Outputs
output "smtp_username" {
  description = "The IAM access key ID for SMTP user"
  value       = length(aws_iam_access_key.smtp_user_key) > 0 ? aws_iam_access_key.smtp_user_key[0].id : null
}

output "smtp_password" {
  description = "The SMTP password for SES (derived from access key)"
  value       = length(aws_iam_access_key.smtp_user_key) > 0 ? aws_iam_access_key.smtp_user_key[0].ses_smtp_password_v4 : null
  sensitive   = true
}