locals {
  ldap_config_lower_environments = {
    name                        = "ldap_for_lower_environments"
    migration_source_account_id = local.application_data.accounts[local.environment].migration_source_account_id # legacy pre-prod account
    migration_lambda_role       = "ldap-data-migration-lambda-role"                                              # IAM role in legacy pre-prod account
    efs_throughput_mode         = "bursting"
    efs_provisioned_throughput  = null
  }

  weblogic_config_lower_environments = {
    name                          = "weblogic_for_lower_environments"
    frontend_service_name         = "weblogic"
    frontend_fully_qualified_name = "${local.application_name}-${local.frontend_service_name}"
    frontend_image_tag            = "5.7.6"
    frontend_container_port       = 8080
    frontend_url_suffix           = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  }

  db_config_lower_environments = {
    name     = "db_for_lower_environments"
    ami_name = "delius_core_ol_8_5_oracle_db_19c_patch_2023-06-12T12-32-07.259Z"
  }

}
