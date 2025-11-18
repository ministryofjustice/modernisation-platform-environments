####################################################################
# SES domain identities, verifications, config sets and dkim configs
####################################################################

###########################
# Preproduction Environment
###########################
/*
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
    for env, identity in aws_ses_domain_identity.ppud :
    env => {
      verification_txt = {
        name  = "_amazonses.${identity.domain}"
        type  = "TXT"
        value = identity.verification_token
      }
      dkim_cnames = [
        for token in aws_ses_domain_dkim.Domain-DKIM[env].dkim_tokens :
        {
          name  = "${token}._domainkey.${identity.domain}"
          type  = "CNAME"
          value = "${token}.dkim.amazonses.com"
        }
      ]
      mail_from_mx = {
        name  = aws_ses_domain_mail_from.ppud[env].mail_from_domain
        type  = "MX"
        value = "10 feedback-smtp.eu-west-2.amazonses.com"
      }
      spf_txt = {
        name  = identity.domain
        type  = "TXT"
        value = "v=spf1 include:amazonses.com ~all"
      }
      dmarc_txt = {
        name  = "_dmarc.${identity.domain}"
        type  = "TXT"
        value = "v=DMARC1; p=none; rua=mailto:dmarc-reports@${identity.domain}; adkim=s; aspf=s"
      }
    }
  }
}
*/
#######################################################################
# SES v2 Domain Identities, Configuration Sets, Event Destinations
#######################################################################

#######################################################################
# SES Environment Configuration (excluding production)
#######################################################################

locals {
  ses_environments = {
    development = {
      condition = local.is-development
    }
    preproduction = {
      condition = local.is-preproduction
    }
  }

  ses_instances = {
    for env_key, env_config in local.ses_environments : env_key => env_config
    if env_config.condition
  }
}

#######################################################################
# SES Domain Identity (Development and Preproduction only)
#######################################################################

resource "aws_sesv2_email_identity" "ppud_domain" {
  for_each = local.ses_instances

  email_identity = local.application_data.accounts[local.environment].SES_domain

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
  
  tags = {
    IdentityName = local.application_data.accounts[local.environment].SES_domain
    Environment  = each.key
    Service      = "SESv2"
  }
}

#######################################################################
# SES Domain Mail From
#######################################################################

resource "aws_sesv2_email_identity_mail_from_attributes" "ppud_mail_from" {
  for_each = local.ses_instances

  email_identity   = aws_sesv2_email_identity.ppud_domain[each.key].email_identity
  mail_from_domain = "noreply.${aws_sesv2_email_identity.ppud_domain[each.key].email_identity}"
}

#######################################################################
# SES Configuration Sets
#######################################################################

resource "aws_sesv2_configuration_set" "ses_events_configuration_set" {
  for_each = local.ses_instances
  
  configuration_set_name = "ses-events-configuration-set-${each.key}"

  delivery_options {
    tls_policy = "OPTIONAL"
  }

  tags = {
    IdentityName  = aws_sesv2_email_identity.ppud_domain[each.key].email_identity
    Environment   = each.key
    Service       = "SESv2"
  }
}

#######################################################################
# SES Event Destinations
#######################################################################

resource "aws_sesv2_configuration_set_event_destination" "ses_delivery_events" {
  for_each = local.ses_instances

  configuration_set_name = aws_sesv2_configuration_set.ses_events_configuration_set[each.key].configuration_set_name
  event_destination_name = "ses-delivery-events-${each.key}"
  
  event_destination {
    enabled          = true
    matching_event_types = ["SEND"]  # "DELIVERY", "BOUNCE", "COMPLAINT" options also available

    sns_destination {
      topic_arn = aws_sns_topic.ses_logging[each.key].arn
    }
  }
}

#######################################################################
# Outputs for DNS records (for domain verification)
#######################################################################

output "ses_verification_records" {
  value = {
    for env, identity in aws_sesv2_email_identity.ppud_domain :
    env => {
      dkim_cnames = [
        for token in identity.dkim_signing_attributes[0].tokens :
        {
          name  = "${token}._domainkey.${identity.email_identity}"
          type  = "CNAME"
          value = "${token}.dkim.amazonses.com"
        }
      ]
      mail_from_mx = {
        name  = "noreply.${identity.email_identity}"
        type  = "MX"
        value = "10 feedback-smtp.eu-west-2.amazonses.com"
      }
      spf_txt = {
        name  = identity.email_identity
        type  = "TXT"
        value = "v=spf1 include:amazonses.com ~all"
      }
      dmarc_txt = {
        name  = "_dmarc.${identity.email_identity}"
        type  = "TXT"
        value = "v=DMARC1; p=none;"
      }
    }
  }
}
