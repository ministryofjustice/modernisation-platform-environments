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

  configuration_set_name = "ses-events-configuration-set-${each.key}"

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
    IdentityName = aws_sesv2_email_identity.ppud_domain[each.key].email_identity
    Environment  = each.key
    Service      = "SESv2"
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
    enabled              = true
    matching_event_types = ["SEND"] # "DELIVERY", "BOUNCE", "COMPLAINT" options also available

    sns_destination {
      topic_arn = aws_sns_topic.ses_logging[each.key].arn
    }
  }
}
