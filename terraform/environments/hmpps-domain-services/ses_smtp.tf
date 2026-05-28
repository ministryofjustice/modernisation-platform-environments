locals {
  ses_domain = "hmpps-domain.service.justice.gov.uk"
}

### SES ###

resource "aws_ses_domain_identity" "hmpps_domain" {
  count = local.is-production == true ? 1 : 0

  domain = local.ses_domain
}

resource "aws_ses_domain_dkim" "hmpps_domain_dkim" {
  count = local.is-production == true ? 1 : 0

  domain = aws_ses_domain_identity.hmpps_domain[0].domain
}


### Route 53 Records ###

# SES looks for this record to verify we own the domain.
resource "aws_route53_record" "ses_verification" {
  count = local.is-production == true ? 1 : 0

  zone_id = module.baseline.route53_zones[local.ses_domain].zone_id
  name    = "_amazonses.${aws_ses_domain_identity.hmpps_domain[0].domain}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.hmpps_domain[0].verification_token]
}

# These are DKIM records to authenticate emails came from the domain.
resource "aws_route53_record" "email_dkim_records" {
  count = local.is-production == true ? 3 : 0

  zone_id = module.baseline.route53_zones[local.ses_domain].zone_id
  name    = "${element(aws_ses_domain_dkim.hmpps_domain_dkim[0].dkim_tokens, count.index)}._domainkey.${aws_ses_domain_identity.hmpps_domain[0].domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [
    "${element(aws_ses_domain_dkim.hmpps_domain_dkim[0].dkim_tokens, count.index)}.dkim.amazonses.com",
  ]
}

### SMTP User ###

resource "aws_iam_user" "ses_smtp_user" {
  # checkov:skip=CKV_AWS_273:Required for SMTP

  count = local.is-production == true ? 1 : 0

  name = "ses_smtp_user"
}

resource "aws_iam_user_policy" "ses_smtp_user" {
  # checkov:skip=CKV_AWS_40:Policy attached to User due to Modernisation Platform restrictions
  # checkov:skip=CKV_AWS_290:Policy does not deal with write access

  count = local.is-production == true ? 1 : 0

  user = aws_iam_user.ses_smtp_user[0].name
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Effect : "Allow"
        Action : "ses:SendRawEmail"
        Resource : aws_ses_domain_identity.hmpps_domain[0].arn
      }
    ]
  })
}

resource "aws_iam_access_key" "ses_smtp_user" {
  count = local.is-production == true ? 1 : 0

  user = aws_iam_user.ses_smtp_user[0].name
}

resource "aws_ssm_parameter" "ses_smtp_user" {
  count = local.is-production == true ? 1 : 0

  name   = "/ses-smtp-user"
  type   = "SecureString"
  key_id = data.aws_kms_key.general_shared.arn
  value = jsonencode({
    user = aws_iam_user.ses_smtp_user[0].name,
    # The two below are used as a username and password when accessing the
    # SES SMTP server.
    # See the AWS Management Console for server details -- hostname, port, etc.
    ses_smtp_user     = aws_iam_access_key.ses_smtp_user[0].id
    ses_smtp_password = aws_iam_access_key.ses_smtp_user[0].ses_smtp_password_v4
  })
}
