##############################################
### SES Domain Identity + DKIM
###
### Verifies the sending domain so emails pass
### DMARC alignment. Uses a workspace-specific
### subdomain to avoid conflicts.
###
### Sender address: no-reply@<subdomain>
### e.g. no-reply@workspaces-new.laa-development.modernisation-platform.service.justice.gov.uk
##############################################

resource "aws_ses_domain_identity" "workspaces" {

  domain = "workspaces-new.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
}

resource "aws_ses_domain_dkim" "workspaces" {

  domain = aws_ses_domain_identity.workspaces.domain
}

# Route53 TXT record for SES domain ownership verification
resource "aws_route53_record" "ses_verification" {

  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "_amazonses.${aws_ses_domain_identity.workspaces.domain}"
  type     = "TXT"
  ttl      = 600
  records  = [aws_ses_domain_identity.workspaces.verification_token]
}

resource "aws_ses_domain_identity_verification" "workspaces" {

  domain = aws_ses_domain_identity.workspaces.domain

  depends_on = [aws_route53_record.ses_verification]
}

# Route53 CNAME records for DKIM signing (3 records required)
resource "aws_route53_record" "ses_dkim" {
  count = 3

  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${aws_ses_domain_dkim.workspaces.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.workspaces.domain}"
  type     = "CNAME"
  ttl      = 600
  records  = ["${aws_ses_domain_dkim.workspaces.dkim_tokens[count.index]}.dkim.amazonses.com"]
}
