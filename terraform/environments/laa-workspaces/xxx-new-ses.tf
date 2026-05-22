##############################################
### SES Domain Identity + DKIM
###
### Verifies the sending domain so emails pass
### DMARC alignment. Uses the existing Route53
### hosted zone (same domain as the ALB record).
###
### Sender address: no-reply@<domain>
### e.g. no-reply@laa-development.modernisation-platform.service.justice.gov.uk
##############################################

resource "aws_ses_domain_identity" "workspaces" {
  count = local.environment == "development" ? 1 : 0

  domain = trimsuffix(data.aws_route53_zone.external.name, ".")
}

resource "aws_ses_domain_dkim" "workspaces" {
  count = local.environment == "development" ? 1 : 0

  domain = aws_ses_domain_identity.workspaces[0].domain
}

# Route53 TXT record for SES domain ownership verification
resource "aws_route53_record" "ses_verification" {
  count = local.environment == "development" ? 1 : 0

  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "_amazonses.${aws_ses_domain_identity.workspaces[0].domain}"
  type     = "TXT"
  ttl      = 600
  records  = [aws_ses_domain_identity.workspaces[0].verification_token]
}

resource "aws_ses_domain_identity_verification" "workspaces" {
  count = local.environment == "development" ? 1 : 0

  domain = aws_ses_domain_identity.workspaces[0].domain

  depends_on = [aws_route53_record.ses_verification]
}

# Route53 CNAME records for DKIM signing (3 records required)
resource "aws_route53_record" "ses_dkim" {
  count = local.environment == "development" ? 3 : 0

  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${aws_ses_domain_dkim.workspaces[0].dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.workspaces[0].domain}"
  type     = "CNAME"
  ttl      = 600
  records  = ["${aws_ses_domain_dkim.workspaces[0].dkim_tokens[count.index]}.dkim.amazonses.com"]
}

##############################################
### Outputs
##############################################

output "ses_sender_email" {
  value       = local.environment == "development" ? "no-reply@${aws_ses_domain_identity.workspaces[0].domain}" : null
  description = "SES verified sender email address"
}
