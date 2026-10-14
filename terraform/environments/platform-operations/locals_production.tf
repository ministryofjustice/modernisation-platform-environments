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

  github_actions_lambda_production = {
    enable_outbound_federation = true
    github_workflows = {
      azure-fixngo-dso-devtest-drift-check = {
        identity = "platops"
        inputs = {
          projects = "nomisapi-t3 resource_locks dso-terraform-state"
          action   = "driftcheck"
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
          projects = "resource_locks"
          action   = "apply"
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
          projects = "nomisapi-preprod resource_locks dso-terraform-state webops-prod nomisapi-prod"
          action   = "driftcheck"
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
          projects = "resource_locks"
          action   = "apply"
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
          projects = "noms-prod-alert-rules automation_account Network-NOMS-Live dso-passwords-prod dso-boot-diagnostics Network-NOMS-Routes noms-prod-azure-monitor dso-certs resource_locks NetworkWatcher log_analytics dso-terraform-state Network-NOMS-Transit-Live noms-live noms-mgmt-live dso-passwords-devtest-backup Network-NOMS-Mgmt-Live pd-noncoreapps"
          action   = "driftcheck"
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
          projects = "resource_locks"
          action   = "apply"
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
          projects = "resource_locks log_analytics dso-terraform-state"
          action   = "driftcheck"
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
          projects = "resource_locks"
          action   = "apply"
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
      dso-certificates-cert-renewal-prod = {
        identity = "platops"
        inputs   = {}

        ref      = "main"
        repo     = "dso-certificates"
        schedule = "cron(00 5 ? * TUE-THU *)"
        timezone = "Europe/London"
        workflow = "cert-renewal-prod.yml"
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
    }
  }
}
