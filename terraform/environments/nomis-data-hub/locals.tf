#### This file can be used to store locals specific to the member account ####

locals {
  business_unit = var.networking[0].business-unit

  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_environment_config = local.environment_configs[local.environment]
  environment_config          = local.environment_configs[local.environment]
  ndh_secrets = [
    "ndh_admin_user",
    "ndh_admin_pass",
    "ndh_domain_name",
    "ndh_ems_host_a",
    "ndh_ems_host_b",
    "ndh_app_host_a",
    "ndh_app_host_b",
    "ndh_ems_port_1",
    "ndh_ems_port_2",
    "ndh_host_os",
    "ndh_host_os_version",
    "ndh_harkemsadmin_ssl_pass",
  ]

  baseline_ssm_parameters = {
    "" = {
      postfix = ""
      parameters = {
        cloud-watch-config-windows = {
          description = "cloud watch agent config for windows"
          file        = "./templates/cloud_watch_windows.json"
          type        = "String"
        }
      }
    }
  }

  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }
}
