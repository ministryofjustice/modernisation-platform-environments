resource "aws_route53_record" "airflow" {
  zone_id = data.aws_route53_zone.network_services.zone_id
  name    = "airflow"
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.mwaa_alb.dns_name]
}

resource "aws_route53_record" "ses_verification" {
  zone_id = data.aws_route53_zone.network_services.zone_id
  name    = "_amazonses"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.main.verification_token]
}

resource "aws_route53_record" "dkim_0" {
  zone_id = data.aws_route53_zone.network_services.zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[0]}._domainkey"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[0]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "dkim_1" {
  zone_id = data.aws_route53_zone.network_services.zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[1]}._domainkey"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[1]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "dkim_2" {
  zone_id = data.aws_route53_zone.network_services.zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[2]}._domainkey"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[2]}.dkim.amazonses.com"]
}
