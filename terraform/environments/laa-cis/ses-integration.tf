#####################################
# SES Route53 Records
#####################################

locals {
  ses_base_domain      = "modernisation-platform.service.justice.gov.uk"
  ses_environment_name = try(local.application_data.accounts[local.environment].ses_environment_name, null)
  ses_domain_identity  = local.ses_environment_name == null ? null : "${local.ses_environment_name}.${local.ses_base_domain}"
  ses_dkim_tokens      = try(local.application_data.accounts[local.environment].ses_dkim_tokens, [])
  ses_mail_from_name   = try(local.application_data.accounts[local.environment].ses_mail_from_subdomain, "mail")

  ses_mail_from_domain = local.ses_domain_identity == null ? null : "${local.ses_mail_from_name}.${local.ses_domain_identity}"

  ses_dkim_records = local.ses_domain_identity == null ? [] : [
    for token in local.ses_dkim_tokens : {
      name  = "${token}._domainkey.${local.ses_domain_identity}"
      type  = "CNAME"
      value = "${token}.dkim.amazonses.com"
    }
  ]

  ses_mail_from_mx_record = {
    name     = local.ses_mail_from_domain
    priority = 10
    type     = "MX"
    value    = "feedback-smtp.eu-west-2.amazonses.com"
  }

  ses_mail_from_spf_record = {
    name  = local.ses_mail_from_domain
    type  = "TXT"
    value = "v=spf1 include:amazonses.com ~all"
  }
}

resource "aws_route53_record" "ses_dkim" {
  provider = aws.core-network-services
  for_each = { for record in local.ses_dkim_records : record.name => record }

  zone_id = data.aws_route53_zone.network-services.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 600
  records = [each.value.value]
}

resource "aws_route53_record" "ses_mail_from_mx" {
  provider = aws.core-network-services
  count    = local.ses_mail_from_domain == null ? 0 : 1

  zone_id = data.aws_route53_zone.network-services.zone_id
  name    = local.ses_mail_from_mx_record.name
  type    = local.ses_mail_from_mx_record.type
  ttl     = 600
  records = ["${local.ses_mail_from_mx_record.priority} ${local.ses_mail_from_mx_record.value}"]
}

resource "aws_route53_record" "ses_mail_from_spf" {
  provider = aws.core-network-services
  count    = local.ses_mail_from_domain == null ? 0 : 1

  zone_id = data.aws_route53_zone.network-services.zone_id
  name    = local.ses_mail_from_spf_record.name
  type    = local.ses_mail_from_spf_record.type
  ttl     = 600
  records = [local.ses_mail_from_spf_record.value]
}
