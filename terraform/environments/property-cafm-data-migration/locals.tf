locals {
  account_name = "cafm"
  # Flat list of all users across environments
  sftp_user_list = [
    # {
    #   environment  = "development"
    #   user_name    = "dev_user1"
    #   s3_bucket    = "property-datahub-landing-development"
    #   ssm_key_name = "/sftp/keys/dev_user1"
    # },
    # {
    #   environment  = "development"
    #   user_name    = "dev_user2"
    #   s3_bucket    = "property-datahub-landing-development"
    #   ssm_key_name = "/sftp/keys/dev_user2"
    # },
    {
      environment  = "preproduction"
      user_name    = "preprod_sftp_user"
      s3_bucket    = "property-datahub-landing-preproduction"
      ssm_key_name = "/sftp/keys/preprod_sftp_user"
    },
    {
      environment  = "production"
      user_name    = "planetfm_sftp_user"
      s3_bucket    = "property-datahub-landing-production"
      ssm_key_name = "/sftp/keys/planetfm_sftp_user"
    }
  ]

  # Convert list to map keyed by username, filtered to the current environment
  environment_configuration = {
    transfer_server_hostname = "CAFM SFTP Server"

    transfer_server_sftp_users = {
      for user in local.sftp_user_list :
      user.user_name => {
        user_name    = user.user_name
        s3_bucket    = user.s3_bucket
        ssm_key_name = user.ssm_key_name
      }
      if user.environment == local.environment
    }
  }
  environment_map = {
    "production"    = "prod"
    "preproduction" = "preprod"
    "test"          = "test"
    "development"   = "dev"
  }
  environment_shorthand = local.environment_map[local.environment]

  # S3 replication configuration for property-datahub-staging bucket
  replication_configuration = lookup(local.replication_configurations, local.environment, null)

  replication_configurations = {
    production = {
      property_datahub_staging_egress_target_bucket = "mojap-ingestion-production-property-datahub-staging-egress"
      property_datahub_staging_egress_account_id    = local.environment_management.account_ids["analytical-platform-ingestion-production"]
      property_datahub_staging_egress_kms_arn       = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["analytical-platform-ingestion-production"]}:key/6da79242-5b40-4a37-bbdf-961950ced1f4"
    }
  }
}
