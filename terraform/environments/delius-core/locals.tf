#### This file can be used to store locals specific to the member account ####
locals {
  db_service_name         = "testing-db"
  db_fully_qualified_name = "${local.application_name}-${local.db_service_name}"
  db_image_tag            = "5.7.4"
  db_port                 = 1521
  db_name                 = "MODNDA"

  frontend_url            = "${local.application_name}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  frontend_image_tag      = "5.7.6"
  frontend_container_port = 8080

  delius_environments_per_account = {
    # account = [env1, env2]
    prod     = []
    pre_prod = ["stage", "preprod"]
    test     = ["test"]
    dev      = ["dev"]
  }

 
  delius_environment_names = flatten(values(local.delius_environments_per_account))

  ordered_subnet_ids = [data.aws_subnets.shared-private-a.ids[0], data.aws_subnets.shared-private-b.ids[0], data.aws_subnets.shared-private-c.ids[0]]

  all_mp_account_names = keys(local.environment_management.account_ids)
 
  dms_client_account_ids = flatten(concat(
    try(local.dms_config_dev.audit_target_endpoint.write_environment, null) == null ? [] :
    (local.dms_config_dev.audit_target_endpoint.write_environment == local.environment ? [local.environment_management.account_ids["delius-core-development"]] : []),
    try(local.dms_config_test.audit_target_endpoint.write_environment, null) == null ? [] :
    (local.dms_config_test.audit_target_endpoint.write_environment == local.environment ? [local.environment_management.account_ids["delius-core-test"]] : []),
    try(local.dms_config_stage.audit_target_endpoint.write_environment, null) == null ? [] :
    (local.dms_config_stage.audit_target_endpoint.write_environment == local.environment ? [local.environment_management.account_ids["delius-core-stage"]] : []),
    try(local.dms_config_preprod.audit_target_endpoint.write_environment, null) == null ? [] :
    (local.dms_config_preprod.audit_target_endpoint.write_environment == local.environment ? [local.environment_management.account_ids["delius-core-preprod"]] : []))
  )

  env_name_to_dms_config_map = {
    "dev"     = merge({dms_config = local.dms_config_dev},     {account_id = try(local.environment_management.account_ids["delius-core-development"],null)})
    "test"    = merge({dms_config = local.dms_config_test},    {account_id = try(local.environment_management.account_ids["delius-core-test"],null)})
    "stage"   = merge({dms_config = local.dms_config_stage},   {account_id = try(local.environment_management.account_ids["delius-core-preproduction"],null)})
    "preprod" = merge({dms_config = local.dms_config_preprod}, {account_id = try(local.environment_management.account_ids["delius-core-preproduction"],null)})
    }

  # dms_client_account_ids_2 = [for delius_environment in keys(local.env_name_to_account_id_map) :
  #     key if try(local["dms_config_${delius_environment}.audit_target_endpoint.write_environment"],null) == local.environment] 




}
