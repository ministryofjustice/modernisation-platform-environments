locals {
  baseline_presets_preproduction = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs  = true
    }
  }

  baseline_preproduction = {
  }

  security_group_cidrs_preproduction = {
    bastion = flatten([
      "10.161.98.0/28",
      "10.161.98.16/28",
      "10.161.98.32/28"
    ])
  }
}
