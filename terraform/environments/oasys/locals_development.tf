locals {

  delius_oasys_queues_development = {
    "dev" = {
      ip_allow_list = flatten([
        module.ip_addresses.mp_cidrs.non_live_eu_west_nat,
        module.ip_addresses.moj_cidr.moj_aws_digital_macos_globalprotect_alpha,
        # Capita ranges
        "85.115.52.180/32",
        "85.115.52.200/29",
        "85.115.53.180/32",
        "85.115.53.200/29",
        "85.115.54.180/32",
        "85.115.54.200/29",
        "82.203.33.128/28",
        "82.203.33.112/28",
        "172.167.141.40/32",
        "51.104.16.30/31",
      ])
    }
  }

  baseline_presets_development = {
    options = {
      # disabling some features in development as the environment gets nuked
      cloudwatch_metric_oam_links_ssm_parameters = []
      cloudwatch_metric_oam_links                = []
      db_backup_object_lock_days                 = 3
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {
  }
}
