resource "aws_shield_protection" "web_app" {
  name         = "${local.application_name}-${local.environment}-web"
  resource_arn = module.cloudfront_web_app.cloudfront_distribution_arn

  tags = local.tags
}

resource "aws_shield_drt_access_role_arn_association" "this" {
  role_arn = module.iam_role_shield_srt_access.arn
}

resource "aws_shield_proactive_engagement" "this" {
  enabled = true

  emergency_contact {
    contact_notes = "Integration Hub Team"
    email_address = "integration.hub@justice.gov.uk"
    phone_number  = "+12358132134"
  }

  depends_on = [module.iam_role_shield_srt_access]
}