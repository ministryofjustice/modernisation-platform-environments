resource "aws_ses_domain_identity" "main" {
  domain = local.environment_configuration.route53_zone
}

resource "aws_ses_domain_identity_verification" "main" {
  domain = aws_ses_domain_identity.main.domain

  # depends_on = [module.route53_records]
  depends_on = [
    aws_route53_record.ses_verification,
    aws_route53_record.dkim_0,
    aws_route53_record.dkim_1,
    aws_route53_record.dkim_2
  ]
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}
