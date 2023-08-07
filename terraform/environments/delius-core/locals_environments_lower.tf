locals {
  ldap_config_lower_environments = {
    name                        = "ldap_for_lower_environments"
    migration_source_account_id = local.application_data.accounts[local.environment].migration_source_account_id # legacy pre-prod account
    migration_lambda_role       = "ldap-data-migration-lambda-role"                                              # IAM role in legacy pre-prod account
    efs_throughput_mode         = "bursting"
    efs_provisioned_throughput  = null
  }

  db_config_lower_environments = {
    name     = "core-db"
    ami_name = "delius_core_ol_8_5_oracle_db_19c_patch_2023-06-12T12-32-07.259Z"
    instance = {
      disable_api_termination      = true
      instance_type                = "r6i.xlarge"
      key_name                     = "key_name_here"
      metadata_endpoint_enabled    = "enabled"
      metadata_options_http_tokens = "required"
      associate_public_ip_address  = false
      monitoring                   = true
      ebs_block_device_inline      = false
      vpc_security_group_ids       = []
      private_dns_name_options = {
        enable_resource_name_dns_aaaa_record = false
        enable_resource_name_dns_a_record    = true
        hostname_type                        = "ip-name"
      }
    }
  }

  weblogic_config_lower_environments = {
    name                          = "weblogic_for_lower_environments"
    frontend_service_name         = "weblogic"
    frontend_fully_qualified_name = "${local.application_name}-${local.frontend_service_name}"
    frontend_image_tag            = "5.7.6"
    frontend_container_port       = 8080
    frontend_url_suffix           = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  }
}
