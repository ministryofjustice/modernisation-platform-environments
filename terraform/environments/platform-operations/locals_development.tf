locals {
  baseline_presets_development = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs    = true
      cloudwatch_metric_alarms_lambda_function_name = "${local.github_actions_project_name}-trigger"
    }
  }

  baseline_development = {
    cloudwatch_metric_alarms = local.lambda_alarms.development

    options = {
      enable_ec2_session_manager_cloudwatch_logs = true
    }
  }

  github_actions_lambda_development = {
    enable_outbound_federation = false
    github_workflows           = {}
  }
}
