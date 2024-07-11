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

  ordered_subnet_ids = [data.aws_subnets.shared-private-a.ids[0], data.aws_subnets.shared-private-b.ids[0], data.aws_subnets.shared-private-c.ids[0]]

  dms_client_account_arns = concat(
      try(local.dms_config_dev.audit_target_endpoint.write_environment,null) == null ? [] : 
          (local.dms_config_dev.audit_target_endpoint.write_environment == local.environment ? ["arn:aws:iam::${local.environment_management.account_ids["delius-core-development"]}:root"] : []) ,
      try(local.dms_config_test.audit_target_endpoint.write_environment,null) == null ? [] : 
          (local.dms_config_test.audit_target_endpoint.write_environment == local.environment ? ["arn:aws:iam::${local.environment_management.account_ids["delius-core-test"]}:root"] : []),
      try(local.dms_config_stage.audit_target_endpoint.write_environment,null) == null ? [] : 
          (local.dms_config_stage.audit_target_endpoint.write_environment == local.environment ? ["arn:aws:iam::${local.environment_management.account_ids["delius-core-stage"]}:root"] : []),
      try(local.dms_config_preprod.audit_target_endpoint.write_environment,null) == null ? [] : 
          (local.dms_config_preprod.audit_target_endpoint.write_environment == local.environment ? ["arn:aws:iam::${local.environment_management.account_ids["delius-core-preprod"]}:root"] : [])
   )
}
