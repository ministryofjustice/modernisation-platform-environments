####################################################################
# SES domain identities, verifications, config sets and dkim configs
####################################################################

###########################
# Preproduction Environment
###########################

resource "aws_ses_configuration_set" "ses_events_configuration_set_uat" {
  # checkov:skip=CKV_AWS_365: "TLS delivery option has been set to optional."
  count = local.is-preproduction == true ? 1 : 0
  name  = "ses-events-configuration-set-uat"

  delivery_options {
    tls_policy = "Optional"
  }
}

resource "aws_ses_event_destination" "ses_delivery_events_uat" {
  count                  = local.is-preproduction == true ? 1 : 0
  name                   = "ses-delivery-events-uat"
  configuration_set_name = aws_ses_configuration_set.ses_events_configuration_set_uat[0].name
  enabled                = true
  matching_types         = ["send"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_logging_uat[0].arn
  }
}

# Note the SES event destination attachment to the identity has been performed via the GUI as the identity was created there and doesn't exist in the TF code base.

#########################
# Development Environment
#########################

resource "aws_ses_configuration_set" "ses_events_configuration_set_dev" {
  # checkov:skip=CKV_AWS_365: "TLS delivery option has been set to optional."
  count = local.is-development == true ? 1 : 0
  name  = "ses-events-configuration-set-dev"

  delivery_options {
    tls_policy = "Optional"
  }
}

resource "aws_ses_event_destination" "ses_delivery_events_dev" {
  count                  = local.is-development == true ? 1 : 0
  name                   = "ses-delivery-events-dev"
  configuration_set_name = aws_ses_configuration_set.ses_events_configuration_set_dev[0].name
  enabled                = true
  matching_types         = ["send"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_logging_dev[0].arn
  }
}

# Note the SES event destination attachment to the identity has been performed via the GUI as the identity was created there and doesn't exist in the TF code base.

###########################################
# Development and Preproduction Environment
###########################################

resource "aws_ses_domain_identity" "ppud" {
  count  = local.is-production == false ? 1 : 0
  domain = local.application_data.accounts[local.environment].SES_domain
}

resource "aws_ses_domain_identity_verification" "ppud_verification" {
  count  = local.is-production == false ? 1 : 0
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
  count  = local.is-production == false ? 1 : 0
  domain = aws_ses_domain_identity.DKIM-Identity[0].domain
}

#Domain Identity MAIL FROM

resource "aws_ses_domain_mail_from" "ppud" {
  count            = local.is-production == false ? 1 : 0
  domain           = aws_ses_domain_identity.ppud[0].domain
  mail_from_domain = "noreply.${aws_ses_domain_identity.ppud[0].domain}"
}

output "ses_dns_records" {
  value = {
    verification_txt = {
      name  = "_amazonses.${aws_ses_domain_identity.ppud[0].domain}"
      type  = "TXT"
      value = aws_ses_domain_identity.ppud[0].verification_token
    }
    dkim_cnames = [
      for token in aws_ses_domain_dkim.Domain-DKIM[0].dkim_tokens :
      {
        name  = "${token}._domainkey.${aws_ses_domain_identity.ppud[0].domain}"
        type  = "CNAME"
        value = "${token}.dkim.amazonses.com"
      }
    ]
    mail_from_mx = {
      name  = aws_ses_domain_mail_from.ppud[0].mail_from_domain
      type  = "MX"
      value = "10 feedback-smtp.eu-west-2.amazonses.com"
    }
    spf_txt = {
      name  = aws_ses_domain_identity.ppud[0].domain
      type  = "TXT"
      value = "v=spf1 include:amazonses.com ~all"
    }
    dmarc_txt = {
      name  = "_dmarc.${aws_ses_domain_identity.ppud[0].domain}"
      type  = "TXT"
      value = "v=DMARC1; p=none; rua=mailto:dmarc-reports@${aws_ses_domain_identity.ppud[0].domain}; adkim=s; aspf=s"
    }
  }
}