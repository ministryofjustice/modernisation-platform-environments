locals {
  secret_prefix = "${var.account_info.application_name}-${var.env_name}-oracle"

  dba_secret_name = "${local.secret_prefix}-dba-passwords"

  application_secret_name = "${local.secret_prefix}-application-passwords"

  oem_account_id = var.platform_vars.environment_management.account_ids[join("-", ["hmpps-oem", var.account_info.mp_environment])]

  oracle_statistics_map = {
    "dev" = {
      #       "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-test"]
      #       "target_environment" = "test"
    },
    "test" = {
      "source_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-development"]
      "source_environment" = "dev"
    },
    #     "stage" = {
    #       "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-production"]
    #       "target_environment" = "prod"
    #     },
    #     "preprod" = {
    #       "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-production"]
    #       "target_environment" = "prod"
    #     },
    #     "prod" = {
    #       "source_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-preproduction"]
    #       "source_environment" = "preprod"
    #     }
  }

  oracle_duplicate_map = {
    "dev" = {
      #       "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-test"]
      #       "target_environment" = "test"
    }
    "test" = {
      "source_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-development"]
      "source_environment" = "dev"
    },
    #     "stage" = {
    #       "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-production"]
    #       "target_environment" = "prod"
    #     },
    #     "preprod" = {
    #       "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-production"]
    #       "target_environment" = "prod"
    #     },
    #     "prod" = {
    #       "source_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-preproduction"]
    #       "source_environment" = "preprod"
    #     }
  }

  oracle_backup_bucket_prefix = "${var.account_info.application_name}-${var.env_name}-oracle-database-backups"
}
