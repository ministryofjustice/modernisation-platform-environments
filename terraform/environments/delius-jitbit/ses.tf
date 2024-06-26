#############
# SES
#############"

resource "aws_sesv2_email_identity" "jitbit" {
  email_identity         = local.app_url
  configuration_set_name = aws_sesv2_configuration_set.jitbit_ses_configuration_set.configuration_set_name
}

resource "aws_sesv2_email_identity_mail_from_attributes" "example" {
  email_identity = aws_sesv2_email_identity.jitbit.email_identity

  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
  mail_from_domain       = "mail.${aws_sesv2_email_identity.jitbit.email_identity}"
}

resource "aws_route53_record" "jitbit_amazonses_dkim_record" {
  provider = aws.core-vpc
  count    = local.is-production ? 0 : 3
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${aws_sesv2_email_identity.jitbit.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${local.app_url}"
  type     = "CNAME"
  ttl      = "600"
  records  = ["${aws_sesv2_email_identity.jitbit.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "jitbit_amazonses_dkim_record_prod" {
  provider = aws.core-network-services
  count    = local.is-production ? 3 : 0
  zone_id  = data.aws_route53_zone.network-services-production[0].zone_id
  name     = "${aws_sesv2_email_identity.jitbit.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${local.app_url}"
  type     = "CNAME"
  ttl      = "600"
  records  = ["${aws_sesv2_email_identity.jitbit.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
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

resource "aws_route53_record" "jitbit_amazonses_mail_from_txt_record" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "mail.${aws_sesv2_email_identity.jitbit.email_identity}"
  type     = "TXT"
  ttl      = "600"
  records  = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "jitbit_amazonses_mail_from_txt_record_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.network-services-production[0].zone_id
  name     = "mail.${aws_sesv2_email_identity.jitbit.email_identity}"
  type     = "TXT"
  ttl      = "600"
  records  = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "jitbit_amazonses_mail_from_mx_record" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "mail.${aws_sesv2_email_identity.jitbit.email_identity}"
  type     = "MX"
  ttl      = "600"
  records  = ["10 feedback-smtp.eu-west-2.amazonses.com"]
}

resource "aws_route53_record" "jitbit_amazonses_mail_from_mx_record_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.network-services-production[0].zone_id
  name     = "mail.${aws_sesv2_email_identity.jitbit.email_identity}"
  type     = "MX"
  ttl      = "600"
  records  = ["10 feedback-smtp.eu-west-2.amazonses.com"]
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

resource "aws_sesv2_configuration_set" "jitbit_ses_configuration_set" {
  configuration_set_name = format("%s-configuration-set", local.application_name)

  suppression_options {
    suppressed_reasons = [
      "BOUNCE",
      "COMPLAINT"
    ]
  }

  tags = local.tags
}
