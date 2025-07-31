resource "aws_ses_domain_identity" "main" {
  domain = local.environment_configuration.route53_zone
}

resource "aws_ses_domain_identity_verification" "main" {
  domain = aws_ses_domain_identity.main.domain

  depends_on = [module.route53_records] # uncomment after moving module.route53_records
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}
