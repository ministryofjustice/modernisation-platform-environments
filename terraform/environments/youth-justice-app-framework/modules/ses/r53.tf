

data "aws_route53_zone" "zones" {
  for_each = { for k, v in var.ses_domain_identities : k => v if v.create_records }
  name     = "${each.value.identity}."
}

resource "aws_route53_record" "ses_verification" {
  for_each = { for k, v in var.ses_domain_identities : k => v if v.create_records }

  zone_id = data.aws_route53_zone.zones[each.value.identity].zone_id
  name    = "_amazonses.${each.value.identity}"
  type    = "TXT"
  ttl     = 300
  records = [aws_ses_domain_identity.main[each.value.identity].verification_token]
}

resource "aws_route53_record" "ses_dkim" {
  for_each = { for k, v in var.ses_domain_identities : k => v if v.create_records }

  zone_id = data.aws_route53_zone.zones[each.value.identity].zone_id
  name    = "${aws_ses_domain_dkim.main[each.value.identity].dkim_tokens[0]}._domainkey" # 3 records required
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.main[each.value.identity].dkim_tokens[0]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "ses_dkim_2" {
  for_each = { for k, v in var.ses_domain_identities : k => v if v.create_records }

  zone_id = data.aws_route53_zone.zones[each.value.identity].zone_id
  name    = "${aws_ses_domain_dkim.main[each.value.identity].dkim_tokens[1]}._domainkey"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.main[each.value.identity].dkim_tokens[1]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "ses_dkim_3" {
  for_each = { for k, v in var.ses_domain_identities : k => v if v.create_records }

  zone_id = data.aws_route53_zone.zones[each.value.identity].zone_id
  name    = "${aws_ses_domain_dkim.main[each.value.identity].dkim_tokens[2]}._domainkey"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.main[each.value.identity].dkim_tokens[2]}.dkim.amazonses.com"]
}

#moj own this one "justice.gov.uk",
#we own this one "dev.yjbservices.yjb.gov.uk"
#moj own this one "yjb.gov.uk",


