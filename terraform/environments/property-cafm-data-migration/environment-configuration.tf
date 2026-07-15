locals {
  replication_configuration = local.replication_configurations[local.environment]

  replication_configurations = {
    production = {
      # Replication configuration for property-datahub-staging bucket
      property_datahub_staging_egress_target_bucket = "mojap-ingestion-production-property-datahub-staging-egress"
      property_datahub_staging_egress_account_id    = local.environment_management.account_ids["analytical-platform-ingestion-production"]
      property_datahub_staging_egress_kms_arn       = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["analytical-platform-ingestion-production"]}:key/6da79242-5b40-4a37-bbdf-961950ced1f4"
    }
  }
}
