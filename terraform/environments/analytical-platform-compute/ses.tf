resource "aws_ses_email_identity" "main" {
  email = local.environment_configuration.route53_zone
}
