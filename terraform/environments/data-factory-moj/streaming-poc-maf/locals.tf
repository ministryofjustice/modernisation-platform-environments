# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  name                       = "streaming-poc-maf"
  deploy_to                  = ["development"]
  opensearch_host            = contains(local.deploy_to, local.environment) ? try(data.aws_opensearch_domain.opensearch["opensearch"].endpoint, null) : null
  msk_bootstrap_brokers      = contains(local.deploy_to, local.environment) ? try(data.aws_msk_bootstrap_brokers.msk["msk"].bootstrap_brokers_sasl_iam, null) : null
  sns_sender_id              = "MOJSTREAMPC"
  sns_monthly_spending_limit = 200

  drone_incursion_alert_emails = [
    "dnguyen@akersystems.com",
    "smir@akersystems.com",
    "nlowthorpe@akersystems.com",
    "slogan@akersystems.com",
    "smalavalli@akersystems.com",
    "vshah@akersystems.com",
  ]
  
# TODO: uncomment when we have sender ID and are out of sandbox mode.
#  drone_incursion_alert_phone_numbers = [
#    "+44##########", # Stuart
#    "+44##########", # Salman
#    "+44##########", # Nick
#    "+44##########"  # Sharath
#  ]

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
