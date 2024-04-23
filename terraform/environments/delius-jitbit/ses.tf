#############
# SES
#############"

resource "aws_ses_domain_identity" "jitbit" {
  domain = local.app_url
}

resource "aws_ses_domain_identity_verification" "jitbit" {
  domain = local.app_url
}

resource "aws_route53_record" "jitbit_ses_verification_record" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "_amazonses.${aws_ses_domain_identity.jitbit.id}"
  type     = "TXT"
  ttl      = "600"
  records  = [aws_ses_domain_identity.jitbit.verification_token]
}

resource "aws_route53_record" "jitbit_ses_verification_record_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.network-services-production[0].zone_id
  name     = "_amazonses.${aws_ses_domain_identity.jitbit.id}"
  type     = "TXT"
  ttl      = "600"
  records  = [aws_ses_domain_identity.jitbit.verification_token]
}

resource "aws_ses_domain_identity_verification" "jitbit_ses_verification" {
  domain     = aws_ses_domain_identity.jitbit.id
  depends_on = [aws_route53_record.jitbit_ses_verification_record]
}

resource "aws_ses_domain_dkim" "jitbit" {
  domain = aws_ses_domain_identity.jitbit.domain
}

resource "aws_route53_record" "jitbit_amazonses_dkim_record" {
  provider = aws.core-vpc
  count    = local.is-production ? 0 : 3
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${aws_ses_domain_dkim.jitbit.dkim_tokens[count.index]}._domainkey.${local.app_url}"
  type     = "CNAME"
  ttl      = "600"
  records  = ["${aws_ses_domain_dkim.jitbit.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "jitbit_amazonses_dkim_record_prod" {
  provider = aws.core-network-services
  count    = local.is-production ? 3 : 0
  zone_id  = data.aws_route53_zone.network-services-production[0].zone_id
  name     = "${aws_ses_domain_dkim.jitbit.dkim_tokens[count.index]}._domainkey.${local.app_url}"
  type     = "CNAME"
  ttl      = "600"
  records  = ["${aws_ses_domain_dkim.jitbit.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "jitbit_amazonses_dmarc_record" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "_dmarc.${local.app_url}"
  type     = "TXT"
  ttl      = "600"
  records  = ["v=DMARC1; p=none;"]
}

resource "aws_route53_record" "jitbit_amazonses_dmarc_record_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.network-services-production[0].zone_id
  name     = "_dmarc.${local.app_url}"
  type     = "TXT"
  ttl      = "600"
  records  = ["v=DMARC1; p=none;"]
}

#####################
# SES SMTP User
#####################

resource "aws_iam_user" "jitbit_ses_smtp_user" {
  name = "${local.environment}-jitbit-smtp-user"
}

resource "aws_iam_access_key" "jitbit_ses_smtp_user" {
  user = aws_iam_user.jitbit_ses_smtp_user.name
}

resource "aws_iam_user_policy" "jitbit_ses_smtp_user" {
  name = "${local.environment}-jitbit-ses-smtp-user-policy"
  user = aws_iam_user.jitbit_ses_smtp_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ses:SendRawEmail",
          "ses:SendEmail"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_ssm_parameter" "jitbit_ses_smtp_user" {
  name = "/${local.environment}/jitbit/ses_smtp"
  type = "SecureString"
  value = jsonencode({
    user              = aws_iam_user.jitbit_ses_smtp_user.name,
    key               = aws_iam_access_key.jitbit_ses_smtp_user.id,
    secret            = aws_iam_access_key.jitbit_ses_smtp_user.secret
    ses_smtp_user     = aws_iam_access_key.jitbit_ses_smtp_user.id
    ses_smtp_password = aws_iam_access_key.jitbit_ses_smtp_user.ses_smtp_password_v4
  })
}

#####################
# SES Monitoring
#####################

resource "aws_cloudwatch_log_group" "jitbit_ses_logs" {
  name              = format("%s-ses", local.application_name)
  retention_in_days = local.application_data.accounts[local.environment].ses_log_retention_days
}

resource "aws_ses_configuration_set" "jitbit_ses_configuration_set" {
  name = format("%s-configuration-set", local.application_name)
}

resource "aws_ses_event_destination" "jitbit_ses_event_destination" {
  configuration_set_name = aws_ses_configuration_set.jitbit_ses_configuration_set.name
  name                   = format("%s-event-destination", local.application_name)
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery"]

  cloudwatch_destination {
    default_value = "default"
    dimension_name = "email"
    value_source = "emailHeader"
  }
}
