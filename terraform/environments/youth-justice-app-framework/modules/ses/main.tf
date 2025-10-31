resource "aws_ses_domain_identity" "main" {
  for_each = var.ses_domain_identities

  domain = each.value.identity
}

resource "aws_ses_domain_identity_verification" "main" {
  for_each = { for k, v in var.ses_domain_identities : k => v if v.create_records }
  domain   = aws_ses_domain_identity.main[each.value.identity].domain

  depends_on = [aws_route53_record.ses_verification, aws_route53_record.ses_dkim, aws_route53_record.ses_dkim_2, aws_route53_record.ses_dkim_3]
}

resource "aws_ses_domain_dkim" "main" {
  for_each = var.ses_domain_identities
  domain   = aws_ses_domain_identity.main[each.value.identity].domain
}


resource "aws_sesv2_configuration_set" "ses_configuration_set" {
  configuration_set_name = format("%s-configuration-set", var.project_name)

  reputation_options {
    reputation_metrics_enabled = false
  }

  tags = var.tags
}


resource "aws_ses_email_identity" "email_identities" {
  count = length(var.ses_email_identities)
  email = var.ses_email_identities[count.index]
}