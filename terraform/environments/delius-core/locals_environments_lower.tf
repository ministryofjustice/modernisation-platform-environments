locals {
  ldap_config_lower_environments = {
    name                 = "ldap_for_lower_environments"
    some_other_attribute = "some_other_attribute_for_ldap_from_lower_environment_config"
  }

  db_config_lower_environments = {
    name                 = "db_for_lower_environments"
    ami_name             = "delius_core_ol_8_5_oracle_db_19c_patch_2023-06-12T12-32-07.259Z"
    instance             = {
      disable_api_termination       = true
      instance_type                 = "r6i.xlarge"
      key_name                      = "key_name_here"
      metadata_endpoint_enabled     = "enabled"
      metadata_options_http_tokens  = "required"
      associate_public_ip_address   = false
      monitoring                    = true
      ebs_block_device_inline       = false
      vpc_security_group_ids        = []
      private_dns_name_options      = {
        enable_resource_name_dns_aaaa_record = false
        enable_resource_name_dns_a_record    = false
        hostname_type                        = "host_name_type_here"
      }
    }
    some_other_attribute = "some_other_attribute_for_db_from_lower_environment_config"
  }

  #user_data_raw       = var.db_config.user_data_raw
  #ebs_volume_config   = var.db_config_ebs_volume_config
  #ebs_volumes         = var.db_config_ebs_volumes
  #route53_records     = var.db_config_route53_records
}
