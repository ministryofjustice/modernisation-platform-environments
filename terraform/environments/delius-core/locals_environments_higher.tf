locals {
  ldap_config_higher_environments = {
    name                 = "ldap_for_higher_environments"
    some_other_attribute = "some_other_attribute_for_ldap_from_higher_environment_config"
  }

  db_config_higher_environments = {
    name                 = "db_for_higher_environments"
    some_other_attribute = "some_other_attribute_for_db_from_higher_environment_config"
  }
}
