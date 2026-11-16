/*
  SES domain identity used by MWAA to send Airflow email notifications
  from noreply@<route53_zone>. Verification is done with Easy DKIM:
  SES generates three tokens and we publish them as CNAME records in the
  environment's Route 53 zone (created by the data-platform/dns component).
*/

data "aws_route53_zone" "environment" {
  name = local.environment_configuration.route53_zone
}

resource "aws_sesv2_email_identity" "mwaa" {
  email_identity = local.environment_configuration.route53_zone

  tags = local.tags
}

resource "aws_route53_record" "mwaa_ses_dkim" {
  count = 3

  zone_id = data.aws_route53_zone.environment.zone_id
  name    = "${aws_sesv2_email_identity.mwaa.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${local.environment_configuration.route53_zone}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_sesv2_email_identity.mwaa.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}