locals {
  baseline_presets_development = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs = true
    }
  }

  baseline_development = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs = true
    }
  }

  enable_aws_health_lambda_development = true

  github_actions_lambda_development = {
    enable_outbound_federation = true
    github_workflows           = {}
  }
}
