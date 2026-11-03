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
      targets = []
    },
    "dev" = {
      targets = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-test"]
          environment = "test"
        }
      ]
    },
    "test" = {
      sources = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-development"]
          environment = "dev"
        }
      ]
    },
    "stage" = {
      sources = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-production"]
          environment = "prod"
        }
      ]
    },
    "preprod" = {
      sources = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-production"]
          environment = "prod"
        }
      ]
    },
    "prod" = {
      #       sources = [
      #         {
      #           account_id  = var.platform_vars.environment_management.account_ids["delius-core-preproduction"]
      #           environment = "preprod"
      #         }
      #       ]
    },
    "training" = {
      targets = []
    }
  }

  # The RAT Capture Map defines which environments can supply RAT Captures with
  # which other environments.
  # targets: environments allowed to pull this environment's RAT captures
  # sources: environments whose RAT captures this environment may pull from
  # Note that live-like environments should not share RAT captures with non-live like
  # environments as capture files may contain sensitive data
  oracle_rat_capture_map = {
    "dev" = {
      targets = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-test"]
          environment = "test"
        }
      ]
      sources = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-test"]
          environment = "test"
        }
      ]
    },
    "test" = {
      targets = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-development"]
          environment = "dev"
        }
      ]
      sources = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-development"]
          environment = "dev"
        }
      ]
    },
    "stage" = {
      sources = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-production"]
          environment = "prod"
        }
      ]
    },
    "preprod" = {
      sources = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-production"]
          environment = "prod"
        }
      ]
    },
    "prod" = {
      #       sources = [
      #         {
      #           account_id  = var.platform_vars.environment_management.account_ids["delius-core-preproduction"]
      #           environment = "preprod"
      #         }
      #       ]
    },
    "training" = {

    }
  }

  oracle_duplicate_map = {
    "poc" = {
      targets = []
      sources = []
    },
    "dev" = {
      targets = []
      sources = []
    }
    "test" = {
      targets = []
      sources = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-development"]
          environment = "dev"
        }
      ]
    },
    "stage" = {
      targets = []
      sources = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-production"]
          environment = "prod"
        }
      ]
    },
    "preprod" = {
      targets = []
      sources = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-production"]
          environment = "prod"
        }
      ]
    },
    "prod" = {
      targets = [
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-preproduction"]
          environment = "stage"
        },
        {
          account_id  = var.platform_vars.environment_management.account_ids["delius-core-preproduction"]
          environment = "preprod"
        }
      ]
      sources = []
    },
    "training" = {
      targets = []
      sources = []
    }
  }

  oracle_backup_bucket_prefix = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}-backups"

  db_port = 1521

  # ap_dev_cidr = "172.24.0.0/16"

  ap_env_cidrs = {
    dev  = "172.24.0.0/16"
    test = "172.24.0.0/16"
    # dev and test ranges are same as they dont have test DMS task
    # and use dev to connect to TEST oracle DB instance
    # include higher envs later
    preprod = "172.26.0.0/16",
    prod    = "172.25.0.0/16"
  }
}
