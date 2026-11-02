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

  enable_aws_health_lambda_production = true

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
    }
  }
}
