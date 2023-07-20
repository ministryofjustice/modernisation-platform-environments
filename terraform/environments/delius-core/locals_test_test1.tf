# Terraform configuration data for environments in delius-core test account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  ldap_config_test1 = {
    name                 = "ldap"
    some_other_attribute = "some_other_attribute_for_ldap_in_test1"
  }

  db_config_test1 = {
    name                 = "db"
    ami_name             = local.db_config_lower_environments.ami_name
    ebs_volume_config    = {}
    ebs_volumes          = {}
    route53_records      = {}
    instance = merge(local.db_config_lower_environments.instance, {
      instance_type = "r6i.xlarge"
      monitoring    = false
    })
    some_other_attribute = "some_other_attribute_for_db_in_test1"
  }
}
