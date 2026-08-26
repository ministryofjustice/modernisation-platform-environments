resource "aws_ses_domain_identity" "external" {
  count  = local.is-production ? 1 : 0
  domain = data.aws_route53_zone.application-zone.name
}

resource "aws_ses_domain_dkim" "external" {
  count      = local.is-production ? 1 : 0
  domain     = aws_ses_domain_identity.external[0].domain
  depends_on = [aws_ses_domain_identity_verification.external]
}

# `allow_overwrite` is used here as this is a verification record
resource "aws_route53_record" "external_amazonses_verification_record" {
  provider        = aws.core-network-services
  count           = local.is-production ? 1 : 0
  zone_id         = data.aws_route53_zone.application-zone.id
  allow_overwrite = true
  name            = format("_amazonses.%s", data.aws_route53_zone.application-zone.name)
  type            = "TXT"
  ttl             = "300"
  records         = [aws_ses_domain_identity.external[0].verification_token]
}

resource "aws_route53_record" "external_amazonses_dkim_record" {
  provider        = aws.core-network-services
  count           = local.is-production ? 3 : 0
  zone_id         = data.aws_route53_zone.application-zone.id
  allow_overwrite = true
  name            = "${element(aws_ses_domain_dkim.external[0].dkim_tokens, count.index)}._domainkey"
  type            = "CNAME"
  ttl             = "300"
  records         = ["${element(aws_ses_domain_dkim.external[0].dkim_tokens, count.index)}.dkim.amazonses.com"]
  depends_on      = [aws_ses_domain_dkim.external[0]]
}

resource "aws_ses_domain_identity_verification" "external" {
  count  = local.is-production ? 1 : 0
  domain = aws_ses_domain_identity.external[0].id

  depends_on = [aws_route53_record.external_amazonses_verification_record]
  timeouts {
    create = "5m"
  }
}