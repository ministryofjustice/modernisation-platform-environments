locals {
  baseline_presets_development = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs  = true
    }
  }

  baseline_development = {
    lbs = {
      api-alb = local.lbs.api-alb,
      web-alb = local.lbs.web-alb
    }
  }
}
