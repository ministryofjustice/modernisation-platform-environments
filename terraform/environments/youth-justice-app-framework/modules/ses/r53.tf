/*
resource "aws_route53_record" "ses_verification" {
  for_each = toset(var.ses_domain_identities)

  zone_id = module.route53_records[each.value].zone_id
  name    = "_amazonses.${each.value}"
  type    = "TXT"
  ttl     = 300
  records = [aws_ses_domain_identity.main[each.value].verification_token]
}

resource "aws_route53_record" "ses_dkim" {
  for_each = toset(var.ses_domain_identities)

  zone_id = module.route53_records[each.value].zone_id
  name    = aws_ses_domain_dkim.main[each.value].dkim_tokens[0]  # 3 records required
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.main[each.value].dkim_tokens[0]}.amazonses.com."]
}

resource "aws_route53_record" "ses_dkim_2" {
  for_each = toset(var.ses_domain_identities)

  zone_id = module.route53_records[each.value].zone_id
  name    = aws_ses_domain_dkim.main[each.value].dkim_tokens[1]
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.main[each.value].dkim_tokens[1]}.amazonses.com."]
}

resource "aws_route53_record" "ses_dkim_3" {
  for_each = toset(var.ses_domain_identities)

  zone_id = module.route53_records[each.value].zone_id
  name    = aws_ses_domain_dkim.main[each.value].dkim_tokens[2]
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.main[each.value].dkim_tokens[2]}.amazonses.com."]
}

"dev.justice.gov.uk","yjb.gov.uk","dev.yjbservices.yjb.gov.uk"
*/
