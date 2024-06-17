#############
# SES
#############

resource "aws_sesv2_email_identity" "nextcloud" {
  email_identity = "${var.env_name}.${var.account_config.dns_suffix}"
}

resource "aws_sesv2_email_identity_mail_from_attributes" "nextcloud" {
  email_identity = aws_sesv2_email_identity.nextcloud.email_identity

  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
  mail_from_domain       = "mail.${aws_sesv2_email_identity.nextcloud.email_identity}"
}

resource "aws_route53_record" "nextcloud_ses_dkim_records" {
  provider = aws.core-vpc
  count    = 3
  zone_id  = var.account_config.route53_external_zone.zone_id
  name     = "${aws_sesv2_email_identity.nextcloud.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${aws_sesv2_email_identity.nextcloud.email_identity}"
  type     = "CNAME"
  ttl      = "600"
  records  = ["${aws_sesv2_email_identity.nextcloud.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "nextcloud_ses_dmarc_record" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_external_zone.zone_id
  name     = "_dmarc.${aws_sesv2_email_identity.nextcloud.email_identity}"
  type     = "TXT"
  ttl      = "600"
  records  = ["v=DMARC1; p=none"]
}

resource "aws_route53_record" "nextcloud_ses_mail_from_txt_record" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_external_zone.zone_id
  name     = "mail.${aws_sesv2_email_identity.nextcloud.email_identity}"
  type     = "TXT"
  ttl      = "600"
  records  = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "nextcloud_ses_mail_from_mx_record" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_external_zone.zone_id
  name     = "mail.${aws_sesv2_email_identity.nextcloud.email_identity}"
  type     = "MX"
  ttl      = "600"
  records  = ["10 feedback-smtp.eu-west-2.amazonses.com"]
}

resource "aws_sesv2_configuration_set" "nexctloud_ses_configuration_set" {
  configuration_set_name = "${var.env_name}-${var.account_info.application_name}-ses-configuration-set"

  suppression_options {
    suppressed_reasons = [
      "BOUNCE",
      "COMPLAINT"
    ]
  }

  tags = var.tags
}

#####################
# SES SMTP User
#####################

resource "aws_iam_user" "nextcloud_ses_smtp_user" {
  #checkov:skip=CKV_AWS_273:Nextcloud requires an SMTP user to send emails
  name = "${var.env_name}-${var.account_info.application_name}-smtp-user"

  tags = var.tags
}

resource "aws_iam_access_key" "nextcloud_ses_smtp_user" {
  user = aws_iam_user.nextcloud_ses_smtp_user.name
}

resource "aws_iam_user_policy" "nextcloud_ses_smtp_user" {
  name = "${var.env_name}-${var.account_info.application_name}-smtp-user-policy"
  user = aws_iam_user.nextcloud_ses_smtp_user.name

  #checkov:skip=CKV_AWS_290:No restrictions can be set in the policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = aws_sesv2_email_identity.nextcloud.arn
      }
    ]
  })
}

resource "aws_ssm_parameter" "nextcloud_ses_smtp_user" {
  name   = "/${var.env_name}/${var.account_info.application_name}/ses_smtp"
  type   = "SecureString"
  key_id = var.account_config.kms_keys.general_shared
  value = jsonencode({
    user              = aws_iam_user.nextcloud_ses_smtp_user.name
    key               = aws_iam_access_key.nextcloud_ses_smtp_user.id
    secret            = aws_iam_access_key.nextcloud_ses_smtp_user.secret
    ses_smtp_user     = aws_iam_access_key.nextcloud_ses_smtp_user.id
    ses_smtp_password = aws_iam_access_key.nextcloud_ses_smtp_user.ses_smtp_password_v4
  })

  tags = var.tags
}