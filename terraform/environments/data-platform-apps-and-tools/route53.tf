resource "aws_route53_zone" "apps_tools" {
  name = local.route53_zone
}

resource "aws_route53_record" "apps_tools_ses_verification" {
  zone_id = aws_route53_zone.apps_tools.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.apps_tools.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.apps_tools.verification_token]
}
