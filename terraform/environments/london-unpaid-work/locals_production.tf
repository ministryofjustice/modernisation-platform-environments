locals {
  baseline_presets_production = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs  = true
    }
  }

  baseline_production = {
  }

  security_group_cidrs_production = {
    bastion = flatten([
      "10.161.98.0/28",
      "10.161.98.16/28",
      "10.161.98.32/28"
    ])
  }
}
