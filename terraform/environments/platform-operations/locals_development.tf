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

  enable_outbound_federation = false

  github_workflows = {}
}
