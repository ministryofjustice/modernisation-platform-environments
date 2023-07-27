# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  network_config_dev1 = {
    shared_vpc_cidr                = data.aws_vpc.shared.cidr_block
    private_subnet_ids             = data.aws_subnets.shared-private.ids
    route53_inner_zone_info        = data.aws_route53_zone.inner
    migration_environment_vpc_cidr = "10.161.20.0/22"
  }

  ldap_config_dev1 = {
    name                        = try(local.ldap_config_lower_environments.name, "ldap")
    migration_source_account_id = local.ldap_config_lower_environments.migration_source_account_id
    migration_lambda_role       = local.ldap_config_lower_environments.migration_lambda_role
    some_other_attribute        = "some_other_attribute_for_ldap_in_dev1"
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
  }

  db_config_dev1 = {
    name                 = try(local.db_config_lower_environments.name, "db")
    ami_name             = local.db_config_lower_environments.ami_name
    some_other_attribute = "some_other_attribute_for_db_in_dev1"
  }
  
}
