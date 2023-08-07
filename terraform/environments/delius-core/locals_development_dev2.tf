# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  network_config_dev2 = {
    shared_vpc_cidr                = data.aws_vpc.shared.cidr_block
    private_subnet_ids             = data.aws_subnets.shared-private.ids
    route53_inner_zone_info        = data.aws_route53_zone.inner
    migration_environment_vpc_cidr = "10.161.20.0/22"
    general_shared_kms_key_arn     = data.aws_kms_key.general_shared.arn
  }

  ldap_config_dev2 = {
    name                        = try(local.ldap_config_lower_environments.name, "ldap")
    migration_source_account_id = local.ldap_config_lower_environments.migration_source_account_id
    migration_lambda_role       = local.ldap_config_lower_environments.migration_lambda_role
    efs_throughput_mode         = local.ldap_config_lower_environments.efs_throughput_mode
    efs_provisioned_throughput  = local.ldap_config_lower_environments.efs_provisioned_throughput
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
  }

  db_config_dev2 = {
    name     = try(local.db_config_lower_environments.name, "db")
    ami_name = local.db_config_lower_environments.ami_name
  }
}
