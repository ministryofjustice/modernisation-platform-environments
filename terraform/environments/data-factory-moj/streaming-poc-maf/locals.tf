# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  name                  = "streaming-poc-maf"
  deploy_to             = ["development"]
  opensearch_host       = contains(local.deploy_to, local.environment) ? try(data.aws_opensearch_domain.opensearch["opensearch"].endpoint, null) : null
  msk_bootstrap_brokers = contains(local.deploy_to, local.environment) ? try(data.aws_msk_bootstrap_brokers.msk["msk"].bootstrap_brokers_sasl_iam, null) : null
  # TODO: uncomment if a sender ID is created and sms is out of sandbox mode.
  #sns_sender_id              = "MOJSTREAMPC"
  #sns_monthly_spending_limit = 200

  drone_incursion_alert_emails = compact(split(",", try(aws_ssm_parameter.drone_incursion_alert_emails[0].value, "")))
  # TODO: uncomment if a sender ID is created and sms is out of sandbox mode.
  #drone_incursion_alert_phone_numbers = compact(split(",", try(aws_ssm_parameter.drone_incursion_alert_phone_numbers[0].value, "")))

  geofence_app = {
    jar_filename = "flink-moj-geofence-1.0.24.jar"
  }

  rules_app = {
    jar_filename = "flink-rules-1.0.26.jar"
  }

  extended_tags = merge(local.tags, {
    component = local.name
  })
}
