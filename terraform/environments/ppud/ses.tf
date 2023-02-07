/*
resource "aws_route53_zone" "asquareus" {
  name = "asquareus.com"
}


resource "aws_route53_zone" "main" {
  name = "asquareus.com"
}

resource "aws_route53_zone" "dev" {
  name = "dev.asquareus.com"

  tags = {
    Environment = "dev"
  }
}

resource "aws_route53_record" "dev-ns" {
  zone_id = data.aws_route53_zone.asquareus.zone_id
  name    = "dev.asquareus.com"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.dev.name_servers
}
*/

resource "aws_ses_domain_identity" "asquareus" {
  domain = "asquareus.com"
}

/*
resource "aws_route53_record" "asquareus_amazonses_verification_record" {
  zone_id = data.aws_route53_zone.asquareus.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.asquareus.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.asquareus.verification_token]
}
*/
resource "aws_ses_domain_identity_verification" "asquareus_verification" {
  domain = aws_ses_domain_identity.asquareus.id
#  depends_on = [aws_route53_record.asquareus_amazonses_verification_record]

    timeouts {
    create = "10m"
  }
}

#SES domain DKIM

resource "aws_ses_domain_identity" "DKIM-Identity" {
  domain = "asquareus.com"
}

resource "aws_ses_domain_dkim" "Domain-DKIM" {
  domain = aws_ses_domain_identity.DKIM-Identity.domain
}

/*
resource "aws_route53_record" "DKIM-amazonses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.asquareus.id
  name    = "${aws_ses_domain_dkim.Domain-DKIM.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.Domain-DKIM.dkim_tokens[count.index]}.dkim.amazonses.com"]
}
*/

#Domain Identity MAIL FROM

resource "aws_ses_domain_mail_from" "asquareus" {
  domain           = aws_ses_domain_identity.asquareus.domain
  mail_from_domain = "bounce.${aws_ses_domain_identity.asquareus.domain}"
}
/*
# Route53 MX record
resource "aws_route53_record" "asquareus_ses_domain_mail_from_mx" {
  zone_id = data.aws_route53_zone.asquareus.id
  name    = aws_ses_domain_mail_from.asquareus.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.eu-west-2.amazonses.com"] # Change to the region in which `aws_ses_domain_identity.example` is created
}

# Route53 TXT record for SPF
resource "aws_route53_record" "asquareus_ses_domain_mail_from_txt" {
  zone_id = data.aws_route53_zone.asquareus.id
  name    = aws_ses_domain_mail_from.asquareus.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}
*/