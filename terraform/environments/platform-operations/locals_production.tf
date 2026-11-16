locals {
  baseline_presets_production = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs    = true
      cloudwatch_metric_alarms_lambda_function_name = "${local.github_actions_project_name}-trigger"
    }
  }

  baseline_production = {
    cloudwatch_metric_alarms = local.lambda_alarms.production

    options = {
      enable_ec2_session_manager_cloudwatch_logs = true
    }
  }

  enable_aws_health_lambda_production         = true
  enable_aws_securityhub_lambda_production    = true
  enable_github_workflow_scheduler_production = true

  github_actions_lambda_production = {
    enable_outbound_federation = true
    github_workflows = {
      azure-ad-application-cleanup = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-infra-azure-ad"
        schedule = "cron(00 8 ? * TUE )"
        timezone = "Europe/London"
        workflow = "application-cleanup.yml"
      }
      azure-ad-application-management = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-infra-azure-ad"
        schedule = "cron(00 2 ? * * )"
        timezone = "Europe/London"
        workflow = "application-management.yml"
      }
      azure-ad-automated-user-management = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-infra-azure-ad"
        schedule = "cron(00 7 ? * TUE )"
        timezone = "Europe/London"
        workflow = "automated-user-management.yml"
      }
      azure-ad-send-reminders = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-infra-azure-ad"
        schedule = "cron(00 9 ? * MON )"
        timezone = "Europe/London"
        workflow = "send-reminders.yml"
      }
      azure-fixngo-dso-devtest-drift-check = {
        identity = "platops"
        inputs = {
          projects      = "driftcheck"
          scheduled_run = "driftcheck"
        }

        ref      = "main"
        repo     = "dso-infra-azure-fixngo"
        schedule = "cron(00 9 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "terragrunt-DigitalStudioDevTestEnvironments.yaml"
      }
      azure-fixngo-dso-devtest-resource-locks = {
        identity = "platops"
        inputs = {
          projects      = "resource_locks"
          scheduled_run = "resource_locks"
        }

        ref      = "main"
        repo     = "dso-infra-azure-fixngo"
        schedule = "cron(00 6 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "terragrunt-DigitalStudioDevTestEnvironments.yaml"
      }
      azure-fixngo-noms-dso-prod1-drift-check = {
        identity = "platops"
        inputs = {
          projects      = "driftcheck"
          scheduled_run = "driftcheck"
        }

        ref      = "main"
        repo     = "dso-infra-azure-fixngo"
        schedule = "cron(00 9 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "terragrunt-NOMSDigitalStudioProduction1.yaml"
      }
      azure-fixngo-noms-dso-prod1-resource-locks = {
        identity = "platops"
        inputs = {
          projects      = "resource_locks"
          scheduled_run = "resource_locks"
        }

        ref      = "main"
        repo     = "dso-infra-azure-fixngo"
        schedule = "cron(00 6 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "terragrunt-NOMSDigitalStudioProduction1.yaml"
      }
      azure-fixngo-noms-prod1-drift-check = {
        identity = "platops"
        inputs = {
          projects      = "driftcheck"
          scheduled_run = "driftcheck"
        }

        ref      = "main"
        repo     = "dso-infra-azure-fixngo"
        schedule = "cron(00 9 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "terragrunt-NOMSProduction1.yaml"
      }
      azure-fixngo-noms-prod1-resource-locks = {
        identity = "platops"
        inputs = {
          projects      = "resource_locks"
          scheduled_run = "resource_locks"
        }

        ref      = "main"
        repo     = "dso-infra-azure-fixngo"
        schedule = "cron(00 6 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "terragrunt-NOMSProduction1.yaml"
      }
      azure-fixngo-platops-drift-check = {
        identity = "platops"
        inputs = {
          projects      = "driftcheck"
          scheduled_run = "driftcheck"
        }

        ref      = "main"
        repo     = "dso-infra-azure-fixngo"
        schedule = "cron(00 9 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "terragrunt-PlatformOperations.yaml"
      }
      azure-fixngo-platops-resource-locks = {
        identity = "platops"
        inputs = {
          projects      = "resource_locks"
          scheduled_run = "resource_locks"
        }

        ref      = "main"
        repo     = "dso-infra-azure-fixngo"
        schedule = "cron(00 6 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "terragrunt-PlatformOperations.yaml"
      }
      azure-fixngo-stale = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-infra-azure-fixngo"
        schedule = "cron(03 1 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "stale.yml"
      }
      dso-certificates-stale = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-certificates"
        schedule = "cron(30 1 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "stale.yml"
      }
      dso-repositories-stale = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-repositories"
        schedule = "cron(30 1 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "stale.yml"
      }
      dso-useful-stuff-stale = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-useful-stuff"
        schedule = "cron(30 1 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "stale.yml"
      }
      hosting-migrations-platops-concierge-to-slack = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "hosting-migrations"
        schedule = "cron(30 6 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "platops-concierge-to-slack.yml"
      }
      hosting-migrations-laa-concierge-to-slack = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "hosting-migrations"
        schedule = "cron(30 6 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "laa-concierge-to-slack.yml"
      }
      mp-automation-certificate-renewal-thursday = {
        identity = "platops"
        inputs = {
          scheduled_run = "thursday"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(30 6 ? * THU *)"
        timezone = "Europe/London"
        workflow = "certificate_renewal.yml"
      }
      mp-automation-certificate-renewal-tuesday = {
        identity = "platops"
        inputs = {
          scheduled_run = "tuesday"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(30 6 ? * TUE *)"
        timezone = "Europe/London"
        workflow = "certificate_renewal.yml"
      }
      mp-automation-certificate-renewal-wednesday = {
        identity = "platops"
        inputs = {
          scheduled_run = "wednesday"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(30 6 ? * WED *)"
        timezone = "Europe/London"
        workflow = "certificate_renewal.yml"
      }
      mp-automation-db-refresh-nomis-1a = {
        identity = "platops"
        inputs = {
          scheduled_run = "preprod_nomis_db_1_a"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(0 7 ? * SUN *)"
        timezone = "Europe/London"
        workflow = "nomis_database_refresh.yml"
      }
      mp-automation-db-refresh-nomis-2a = {
        identity = "platops"
        inputs = {
          scheduled_run = "preprod_nomis_db_2_a"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(0 10 ? * SUN *)"
        timezone = "Europe/London"
        workflow = "nomis_database_refresh.yml"
      }
      mp-automation-db-refresh-oasys-ppoasys = {
        identity = "platops"
        inputs = {
          scheduled_run = "pp_oasys_db_a_PPOASYS"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(0 7 ? * SUN *)"
        timezone = "Europe/London"
        workflow = "oasys_database_refresh.yml"
      }
      mp-automation-db-refresh-oasys-ppoasrep = {
        identity = "platops"
        inputs = {
          scheduled_run = "pp_onr_db_a_PPOASREP"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(0 8 ? * SUN *)"
        timezone = "Europe/London"
        workflow = "oasys_database_refresh.yml"
      }
      mp-automation-db-refresh-oasys-ppmistrn = {
        identity = "platops"
        inputs = {
          scheduled_run = "pp_onr_db_a_PPMISTRN"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(0 9 ? * SUN *)"
        timezone = "Europe/London"
        workflow = "oasys_database_refresh.yml"
      }
      mp-automation-github-workflow-monitoring = {
        identity = "platops"
        inputs = {
          scheduled_run = "monitoring"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(0/30 * * * ? *)"
        timezone = "Europe/London"
        workflow = "github_workflow_monitoring.yml"
      }
      mp-automation-ndh-offloc-cloudplatform-am = {
        identity = "platops"
        inputs = {
          scheduled_run = "ndh_offloc_copy_cloudplatform"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(30 0,3 * * ? *)"
        timezone = "Europe/London"
        workflow = "ndh_offloc_cloudplatfom_copy.yml"
      }
      mp-automation-ndh-offloc-cloudplatform-pm = {
        identity = "platops"
        inputs = {
          scheduled_run = "ndh_offloc_copy_cloudplatform"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(0 0,23 * * ? *)"
        timezone = "Europe/London"
        workflow = "ndh_offloc_cloudplatfom_copy.yml"
      }
      mp-automation-ndh-offloc-copy = {
        identity = "platops"
        inputs = {
          scheduled_run = "ndh_offloc_copy"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(45 23 * * ? *)"
        timezone = "Europe/London"
        workflow = "ndh_offloc_cdecopy.yml"
      }
      mp-automation-ndh-offloc-copy-backup = {
        identity = "platops"
        inputs = {
          scheduled_run = "ndh_offloc_copy"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(20 2 * * ? *)"
        timezone = "Europe/London"
        workflow = "ndh_offloc_cdecopy.yml"
      }
      mp-automation-planetfm-gfsl-data-extract-am = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(10,30 5 * * ? *)"
        timezone = "Europe/London"
        workflow = "planetfm_gfsl_data_extract.yml"
      }
      mp-automation-planetfm-gfsl-data-extract-pm = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(30 12,13 * * ? *)"
        timezone = "Europe/London"
        workflow = "planetfm_gfsl_data_extract.yml"
      }
      mp-automation-security-hub-alerting = {
        identity = "platops"
        inputs = {
          scheduled_run = "security_hub_alerting"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(30 7 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "security_hub_alerting.yml"
      }
      mp-automation-ssm-command-monitoring = {
        identity = "platops"
        inputs = {
          scheduled_run = "ssm_command_monitoring"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(0 * * * ? *)"
        timezone = "Europe/London"
        workflow = "ssm_command_monitoring.yml"
      }
      mp-automation-start-jump-server = {
        identity = "platops"
        inputs = {
          scheduled_run = "jump_server_start"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(45 6 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "jump_server_start.yml"
      }
      mp-automation-stop-jump-server = {
        identity = "platops"
        inputs = {
          scheduled_run = "jump_server_stop"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(5 22 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "jump_server_stop.yml"
      }
      # NCR Stop job is currently disabled, therefore commenting out NCR Start and Stop jobs
      # mp-automation-start-ncr = {
      #   identity = "platops"
      #   inputs = {
      #     scheduled_run = "ncr_environment_start"
      #   }
      #
      #   ref      = "main"
      #   repo     = "dso-modernisation-platform-automation"
      #   schedule = "cron(45 6 ? * MON-FRI *)"
      #   timezone = "Europe/London"
      #   workflow = "ncr_environment_start.yml"
      # }
      # mp-automation-stop-ncr = {
      #   identity = "platops"
      #   inputs = {
      #     scheduled_run = "ncr_environment_stop"
      #   }
      #
      #   ref      = "main"
      #   repo     = "dso-modernisation-platform-automation"
      #   schedule = "cron(5 19 ? * MON-FRI *)"
      #   timezone = "Europe/London"
      #   workflow = "ncr_environment_stop.yml"
      # }
      # NDMIS Stop job is currently disabled, therefore commenting out NCR Start and Stop jobs
      # mp-automation-start-ndmis = {
      #   identity = "platops"
      #   inputs = {
      #     scheduled_run = "ndmis_environment_start"
      #   }
      #
      #   ref      = "main"
      #   repo     = "dso-modernisation-platform-automation"
      #   schedule = "cron(45 6 ? * MON-FRI *)"
      #   timezone = "Europe/London"
      #   workflow = "ndmis_environment_start.yml"
      # }
      # mp-automation-stop-ndmis = {
      #   identity = "platops"
      #   inputs = {
      #     scheduled_run = "ndmis_environment_stop"
      #   }
      #
      #   ref      = "main"
      #   repo     = "dso-modernisation-platform-automation"
      #   schedule = "cron(5 19 ? * MON-FRI *)"
      #   timezone = "Europe/London"
      #   workflow = "ndmis_environment_stop.yml"
      # }
      mp-automation-start-nomis = {
        identity = "platops"
        inputs = {
          scheduled_run = "nomis_environment_start"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(30 6 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "nomis_environment_start.yml"
      }
      mp-automation-stop-nomis = {
        identity = "platops"
        inputs = {
          scheduled_run = "nomis_environment_stop"
        }

        ref      = "main"
        repo     = "dso-modernisation-platform-automation"
        schedule = "cron(5 19 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "nomis_environment_stop.yml"
      }
      # ONR Stop job is currently disabled, therefore commenting out NCR Start and Stop jobs
      # mp-automation-start-onr = {
      #   identity = "platops"
      #   inputs = {
      #     scheduled_run = "onr_environment_start"
      #   }
      #
      #   ref      = "main"
      #   repo     = "dso-modernisation-platform-automation"
      #   schedule = "cron(45 6 ? * MON-FRI *)"
      #   timezone = "Europe/London"
      #   workflow = "onr_environment_start.yml"
      # }
      # mp-automation-stop-onr = {
      #   identity = "platops"
      #   inputs = {
      #     scheduled_run = "onr_environment_stop"
      #   }
      #
      #   ref      = "main"
      #   repo     = "dso-modernisation-platform-automation"
      #   schedule = "cron(5 19 ? * MON-FRI *)"
      #   timezone = "Europe/London"
      #   workflow = "onr_environment_stop.yml"
      # }
    }
  }
}
