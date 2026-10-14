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
