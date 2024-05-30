data "aws_iam_role" "srt_access" {
  name = "AWSSRTSupport"
}

resource "aws_shield_drt_access_role_arn_association" "main" {
  role_arn = data.aws_iam_role.srt_access.arn
}

resource "aws_shield_proactive_engagement" "main" {
  enabled = var.enable_proactive_engagement
  emergency_contact {
    contact_notes = var.enable_proactive_engagement ? "Contact via email." : null
    email_address = var.enable_proactive_engagement ? var.support_email : null
    phone_number  = var.enable_proactive_engagement ? "+440000000000" : null
  }

  depends_on = [aws_shield_drt_access_role_arn_association.main]
}

resource "aws_shield_protection" "this" {
  for_each     = var.shielded_resources
  name         = each.key
  resource_arn = each.value
  tags = merge(var.tags,
    { Name = format("%s-shield-protection", each.key) }
  )
}