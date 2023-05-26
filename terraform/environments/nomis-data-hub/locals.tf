#### This file can be used to store locals specific to the member account ####

locals {
  business_unit = var.networking[0].business-unit

  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  environment_config = local.environment_configs[local.environment]
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
    "ndh_host_os_version"
    "ndh_harkemsadmin_ssl_pass"
  ]
}
