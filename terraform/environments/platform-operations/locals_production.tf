locals {
  baseline_presets_production = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs = true
    }
  }

  baseline_production = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs = true
    }
  }

  github_actions_lambda_development = {
    enable_outbound_federation = true
    github_workflows = {
      hosting-migrations-platops-concierge-to-slack = {
        identity = "platops"
        inputs = {}

        ref      = "main"
        repo     = "hosting-migrations"
        schedule = "cron(30 6 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "platops-concierge-to-slack.yml"
      }
      hosting-migrations-laa-concierge-to-slack = {
        identity = "platops"
        inputs = {}

        ref      = "main"
        repo     = "hosting-migrations"
        schedule = "cron(30 6 ? * MON-FRI *)"
        timezone = "Europe/London"
        workflow = "laa-concierge-to-slack.yml"
      }
    }
  }
}
