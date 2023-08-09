# Terraform configuration data for environments in delius-core test account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  ldap_config_test2 = {
    name                 = "ldap"
    some_other_attribute = "some_other_attribute_for_ldap_in_test2"
  }

  db_config_test2 = {
    name           = try(local.db_config_lower_environments.name, "db")
    ami_name_regex = local.db_config_lower_environments.ami_name_regex
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
    ebs_volume_config = {}
    ebs_volumes       = {}
    route53_records = {
      create_internal_record = true
      create_external_record = false
    }
    tags = merge(local.tags_all,
      {
        Name = lower(format("ec2-%s-%s-base-ami-test-instance", local.application_name, local.environment))
      },
      {
        server-type = "delius_core_db"
    })
  }
}
