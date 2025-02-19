resource "aws_ses_domain_identity" "main" {
  domain = local.environment_configuration.route53_zone
}
