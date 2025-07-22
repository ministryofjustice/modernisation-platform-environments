####################################################################
# SES domain identities, verifications, config sets and dkim configs
####################################################################

###########################
# Preproduction Environment
###########################

resource "aws_ses_configuration_set" "ses_events_configuration_set_uat" {
  count  = local.is-preproduction == false ? 1 : 0
  name   = "ses-events-configuration-set-uat"
}

resource "aws_ses_event_destination" "ses_delivery_events" {
  count                  = local.is-preproduction == false ? 1 : 0
  name                   = "delivery-events"
  configuration_set_name = aws_ses_configuration_set.ses_events_configuration_set_uat[0].name
  enabled                = true

  matching_types = [
    "delivery",
    "bounce",
    "complaint"
  ]

  sns_destination {
    topic_arn = aws_sns_topic.ses_logging_uat[0].arn
  }
}

########################
# Production Environment
########################

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