# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  ldap_config_dev1 = {
    name                 = try(local.ldap_config_lower_environments.name, "ldap")
    some_other_attribute = "some_other_attribute_for_ldap_in_dev1"
  }

  db_config_dev1 = {
    name                 = try(local.db_config_lower_environments.name, "db")
    ami_name             = local.db_config_lower_environments.ami_name
    ebs_volume_config    = {}
    ebs_volumes          = {}
    route53_records      = {}
    instance = merge(local.db_config_lower_environments.instance, {
      instance_type = "r6i.xlarge"
      monitoring    = false
    })
    some_other_attribute = "some_other_attribute_for_db_in_dev1"
  }
}
