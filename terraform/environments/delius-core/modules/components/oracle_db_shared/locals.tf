locals {
  secret_prefix = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}"

  dba_secret_name = "${local.secret_prefix}-dba-passwords"

  application_secret_name = "${local.secret_prefix}-application-passwords"

  oem_account_id = var.platform_vars.environment_management.account_ids[join("-", ["hmpps-oem", var.account_info.mp_environment])]

  mis_account_id = lookup(var.platform_vars.environment_management.account_ids, join("-", ["delius-mis", var.account_info.mp_environment]), null)

  delius_account_id = var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]

  has_mis_environment = lookup(var.environment_config, "has_mis_environment", false)

  oracle_statistics_map = {
    "poc" = {
      #       "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-test"]
      #       "target_environment" = "test"
    },
    "dev" = {
      "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-test"]
      "target_environment" = "test"
    },
    "test" = {
      "source_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-development"]
      "source_environment" = "dev"
    },
    "stage" = {
      # "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-production"]
      # "target_environment" = "prod"
    },
    "preprod" = {
      # "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-production"]
      # "target_environment" = "prod"
    },
    "prod" = {
      #       "source_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-preproduction"]
      #       "source_environment" = "preprod"
    },
    "training" = {

    }
  }

  oracle_duplicate_map = {
    "poc" = {
      #       "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-test"]
      #       "target_environment" = "test"
    },
    "dev" = {
      #       "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-test"]
      #       "target_environment" = "test"
    }
    "test" = {
      "source_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-development"]
      "source_environment" = "dev"
    },
    "stage" = {
      # "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-production"]
      # "target_environment" = "prod"
    },
    "preprod" = {
      # "target_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-production"]
      # "target_environment" = "prod"
    },
    "prod" = {
      #       "source_account_id"  = var.platform_vars.environment_management.account_ids["delius-core-preproduction"]
      #       "source_environment" = "preprod"
    },
    "training" = {
    }
  }

  oracle_backup_bucket_prefix     = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}-backups"
  oracle_backup_bucket_expiration = var.env_name == "prod" ? 373 : 365

  db_port      = 1521

  # ap_dev_cidr = "172.24.0.0/16"

  ap_env_cidrs = {
    dev  = "172.24.0.0/16"
    test = "172.24.0.0/16"
    # dev and test ranges are same as they dont have test DMS task
    # and use dev to connect to TEST oracle DB instance
    # include higher envs later
  }
}
