resource "aws_ses_domain_identity" "ppud" {
  count  = local.is-production == false ? 1 : 0
  domain = local.application_data.accounts[local.environment].SES_domain
}

resource "aws_ses_domain_identity_verification" "ppud_verification" {
  domain = aws_ses_domain_identity.ppud[0].id


  timeouts {
    create = "40m"
  }
}

#SES domain DKIM

resource "aws_ses_domain_identity" "DKIM-Identity" {
  count  = local.is-production == false ? 1 : 0
  domain = local.application_data.accounts[local.environment].SES_domain
}

resource "aws_ses_domain_dkim" "Domain-DKIM" {
  domain = aws_ses_domain_identity.DKIM-Identity[0].domain
}

#Domain Identity MAIL FROM

resource "aws_ses_domain_mail_from" "ppud" {
  domain           = aws_ses_domain_identity.ppud[0].domain
  mail_from_domain = "noreply.${aws_ses_domain_identity.ppud[0].domain}"
}