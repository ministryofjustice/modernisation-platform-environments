# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  network_config_dev = {
    shared_vpc_cidr                = data.aws_vpc.shared.cidr_block
    private_subnet_ids             = data.aws_subnets.shared-private.ids
    route53_inner_zone_info        = data.aws_route53_zone.inner
    migration_environment_vpc_cidr = "10.161.20.0/22"
    general_shared_kms_key_arn      = data.aws_kms_key.general_shared.arn
  }

  ldap_config_dev = {
    name                        = try(local.ldap_config_lower_environments.name, "ldap")
    migration_source_account_id = local.ldap_config_lower_environments.migration_source_account_id
    migration_lambda_role       = local.ldap_config_lower_environments.migration_lambda_role
    efs_throughput_mode         = local.ldap_config_lower_environments.efs_throughput_mode
    efs_provisioned_throughput  = local.ldap_config_lower_environments.efs_provisioned_throughput
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
  }

  db_config_dev = {
    name                 = try(local.db_config_lower_environments.name, "db")
    ami_name             = local.db_config_lower_environments.ami_name
    ami_owner            = local.environment_management.account_ids["core-shared-services-production"]

    user_data_raw = base64encode(
      templatefile(
        "${path.module}/templates/userdata.sh.tftpl",
        {
          branch               = local.db_config.user_data_param.branch
          ansible_repo         = local.db_config.user_data_param.ansible_repo
          ansible_repo_basedir = local.db_config.user_data_param.ansible_repo_basedir
          ansible_args         = local.db_config.user_data_param.ansible_args
        }
      )
    )
    instance = merge(local.db_config_lower_environments.instance, {
      instance_type = "r6i.xlarge"
      monitoring    = false
    })
    ebs_volumes = {}
    #ebs_volumes          = merge(local.database_ec2_a.ebs_volumes, {
    #  "/dev/sda1" = { label = "app", size = 30, type = "gp3" }
    #  "/dev/sdb" = { label = "app", size = 200, type = "gp3" }
    #  "/dev/sdc" = { label = "app", size = 100, type = "gp3" }
    #  "/dev/sds" = { label = "app", size = 4, type = "gp3" }
    #  "/dev/sde" = { label = "app", size = 1, type = "gp3" }
    #  "/dev/sdf" = { label = "app", size = 1, type = "gp3" }
    #  "/dev/sdg" = { label = "app", size = 1, type = "gp3" }
    #  "/dev/sdh" = { label = "app", size = 1, type = "gp3" }
    #  "/dev/sdi" = { label = "app", size = 1, type = "gp3" }
    #  "/dev/sdj" = { label = "app", size = 1, type = "gp3" }
    #  "/dev/sdk" = { label = "app", size = 1, type = "gp3" }
    #})
    ebs_volume_config = {}
    #ebs_volume_config = merge(local.database_ec2_a.ebs_volume_config, {
    #  data  = 
    #  {
    #    total_size = 500 
    #  }
    #  flash = { 
    #    total_size = 50 
    #  }
    #})
    route53_records      = {
      create_internal_record = true
      create_external_record = false
    }
    tags = merge(local.tags_all,
      { Name = lower(format("ec2-%s-%s-base-ami-test-instance", local.application_name, local.environment)) },
      { server-type = "delius_core_db" }
    )
  }

}
