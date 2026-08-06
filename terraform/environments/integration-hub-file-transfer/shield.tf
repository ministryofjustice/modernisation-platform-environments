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