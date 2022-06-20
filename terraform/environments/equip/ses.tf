resource "aws_ses_domain_identity" "external" {
  provider = aws.core-network-services
  domain = data.aws_route53_zone.application-zone.name
}

# `allow_overwrite` is used here as this is a verification record
resource "aws_route53_record" "external_amazonses_verification_record" {
  zone_id = data.aws_route53_zone.external.id
  allow_overwrite = true
  provider = aws.core-network-services
  name    = format("_amazonses.%s", data.aws_route53_zone.application-zone.name)
  type    = "TXT"
  ttl     = "300"
  records = [aws_ses_domain_identity.external.verification_token]
}

resource "aws_ses_domain_identity_verification" "external" {
  provider = aws.core-network-services
  domain = aws_ses_domain_identity.external.id

  depends_on = ["aws_route53_record.external_amazonses_verification_record"]
}

resource "aws_iam_user" "email" {
  name = format("%s-%s-email_user", local.application_name, local.environment)
  tags = merge(local.tags,
    { Name = format("%s-%s-email_user", local.application_name, local.environment) }
  )
}

resource "aws_iam_access_key "email {
  user = aws_iam_user.email.name
}

resource "aws_iam_user_policy" "email_policy" {
  name = format("%s-%s-email_policy", local.application_name, local.environment)
  policy = data.aws_iam_policy_document.email.json
  user   = aws_iam_user.email.name
}