locals {
  ldap_config_higher_environments = {
    name                       = "ldap_for_higher_environments"
    efs_throughput_mode        = "provisioned"
    efs_provisioned_throughput = 64 # MiB/s
  }

  db_config_higher_environments = {
    name = "db_for_higher_environments"
  }
}
