resource "aws_ses_domain_identity" "external" {
  provider = aws.core-network-services
  domain   = data.aws_route53_zone.application-zone.name
}

# `allow_overwrite` is used here as this is a verification record
resource "aws_route53_record" "external_amazonses_verification_record" {
  zone_id         = data.aws_route53_zone.external.id
  allow_overwrite = true
  provider        = aws.core-network-services
  name            = format("_amazonses.%s", data.aws_route53_zone.application-zone.name)
  type            = "TXT"
  ttl             = "300"
  records         = [aws_ses_domain_identity.external.verification_token]
}

resource "aws_ses_domain_identity_verification" "external" {
  provider = aws.core-network-services
  domain   = aws_ses_domain_identity.external.id

  depends_on = [aws_route53_record.external_amazonses_verification_record]
}

data "aws_iam_user" "email" {
  user_name = format("%s-%s-email_policy", local.application_name, local.environment)
}