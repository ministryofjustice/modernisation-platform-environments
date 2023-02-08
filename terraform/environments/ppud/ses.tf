resource "aws_ses_domain_identity" "ppud" {
  count  = local.is-development == true ? 1 : 0
  domain = "internaltest.ppud.justice.gov.uk"
}

resource "aws_ses_domain_identity_verification" "ppud_verification" {
  count  = local.is-development == true ? 1 : 0
  domain = aws_ses_domain_identity.ppud[count.index].id

  timeouts {
    create = "40m"
  }
}

#SES domain DKIM

resource "aws_ses_domain_identity" "DKIM-Identity" {
  count  = local.is-development == true ? 1 : 0
  domain = "internaltest.ppud.justice.gov.uk"
}

resource "aws_ses_domain_dkim" "Domain-DKIM" {
<<<<<<< HEAD
  count  = local.is-development == true ? 1 : 0
  domain = aws_ses_domain_identity.DKIM-Identity[count.index].domain
=======
  # count  = local.is-development == true ? 1 : 0
  domain = aws_ses_domain_identity.DKIM-Identity.domain
>>>>>>> c46e4cf4782da84fbef01315493bbc8150764026
}

#Domain Identity MAIL FROM

resource "aws_ses_domain_mail_from" "ppud" {
<<<<<<< HEAD
  count            = local.is-development == true ? 1 : 0
  domain           = aws_ses_domain_identity.ppud[count.index].domain
  mail_from_domain = "bounce.${aws_ses_domain_identity.ppud[count.index].domain}"
=======
  # count            = local.is-development == true ? 1 : 0
  domain           = aws_ses_domain_identity.ppud.domain
  mail_from_domain = "bounce.${aws_ses_domain_identity.ppud.domain}"
>>>>>>> c46e4cf4782da84fbef01315493bbc8150764026
}