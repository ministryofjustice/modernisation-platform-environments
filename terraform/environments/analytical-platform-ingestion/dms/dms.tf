locals {
  tariff = {
    short_resource_name = "tariff-${local.environment}"
    resource_name       = "cica-ap-tariff-${local.environment}"
  }
  tempus = {
    SPPFinishedJobs = {
      database_name       = "SPPFinishedJobs"
      short_resource_name = "tempus-sppfj-${local.environment}"
      resource_name       = "cica-ap-tempus-spp-finished-jobs-${local.environment}"
      instance_size       = "dms.t3.large"
    }
    SPPProcessPlatform = {
      database_name       = "SPPProcessPlatform"
      short_resource_name = "tempus-spppp-${local.environment}"
      resource_name       = "cica-ap-tempus-spp-process-platform-${local.environment}"
      instance_size       = "dms.r5.large"
    }
    CaseWork = {
      database_name       = "CaseWork"
      short_resource_name = "tempus-cw-${local.environment}"
      resource_name       = "cica-ap-tempus-case-work-${local.environment}"
      instance_size       = "dms.t3.large"
    }
  }
}

module "cica_dms_tariff_dms_implementation" {

  source      = "../modules/dms"
  vpc_id      = data.aws_vpc.connected_vpc.id
  environment = local.environment

  db = local.tariff.short_resource_name

  dms_replication_instance = {
    replication_instance_id    = local.tariff.resource_name
    subnet_cidrs               = local.environment_configuration.connected_vpc_private_subnets
    subnet_group_name          = local.tariff.resource_name
    allocated_storage          = 20
    availability_zone          = data.aws_availability_zones.available.names[0]
    engine_version             = "3.5.4"
    kms_key_arn                = module.cica_dms_credentials_kms.key_arn
    multi_az                   = false
    replication_instance_class = "dms.t3.large"
    inbound_cidr               = local.environment_configuration.tariff_cidr
    apply_immediately          = true
  }
  dms_source = {
    engine_name             = "oracle"
    protocol                = "oracle"
    secrets_manager_arn     = module.cica_dms_tariff_database_credentials.secret_arn
    secrets_manager_kms_arn = module.cica_dms_credentials_kms.key_arn
    sid                     = local.environment_configuration.source_database_sid
    cdc_start_time          = "2025-03-10T12:00:00Z"
  }
  dms_target_prefix = "cica_tariff"
  replication_task_id = {
    full_load = "${local.tariff.resource_name}-full-load"
  }
  dms_mapping_rules = "./metadata/cica_tariff.json"
  output_bucket     = module.cica_dms_ingress_bucket.s3_bucket_id

  tags = local.tags

  create_premigration_assessement_resources = local.environment == "development" ? true : false
  write_metadata_to_glue_catalog            = true
  retry_failed_after_recreate_metadata      = false
  valid_files_mutable                       = true
  glue_catalog_account_id                   = local.environment_management.account_ids["analytical-platform-data-production"]
  glue_catalog_database_name                = "cica-tariff-${local.environment}"
  glue_catalog_role_arn                     = local.environment_configuration.ap_data_glue_catalog_role
  glue_destination_bucket                   = local.environment == "production" ? "mojap-data-production-cica-dms-ingress-production" : ""
  metadata_generator_allowed_triggers = {
    EventBridge = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.metadata_generator.arn
    }
  }
}

module "cica_dms_tempus_dms_implementation" {
  for_each    = local.tempus
  source      = "../modules/dms"
  vpc_id      = data.aws_vpc.connected_vpc.id
  environment = local.environment
  db          = each.value.short_resource_name

  dms_replication_instance = {
    replication_instance_id    = each.value.resource_name
    subnet_cidrs               = local.environment_configuration.connected_vpc_private_subnets
    subnet_group_name          = each.value.resource_name
    allocated_storage          = 20
    availability_zone          = data.aws_availability_zones.available.names[0]
    engine_version             = "3.5.4"
    kms_key_arn                = module.cica_dms_credentials_kms.key_arn
    multi_az                   = false
    replication_instance_class = each.value.instance_size
    inbound_cidr               = local.environment_configuration.tempus_cidr
    apply_immediately          = true
  }
  dms_source = {
    engine_name             = "sqlserver"
    protocol                = "mssql+pymssql"
    secrets_manager_arn     = module.cica_dms_tempus_database_credentials.secret_arn
    secrets_manager_kms_arn = module.cica_dms_credentials_kms.key_arn
    sid                     = each.value.database_name
    cdc_start_time          = "2025-03-10T12:00:00Z"
  }
  dms_target_prefix = "cica_tempus/${each.value.database_name}"
  replication_task_id = {
    full_load = "${each.value.resource_name}-full-load"
  }
  dms_mapping_rules = "./metadata/cica_tempus_${each.value.database_name}.json"
  output_bucket     = module.cica_dms_ingress_bucket.s3_bucket_id

  tags = local.tags

  create_ancillary_static_roles             = false
  create_premigration_assessement_resources = local.environment == "development" ? true : false
  write_metadata_to_glue_catalog            = true
  retry_failed_after_recreate_metadata      = false
  valid_files_mutable                       = true
  glue_catalog_account_id                   = local.environment_management.account_ids["analytical-platform-data-production"]
  glue_catalog_database_name                = "cica-tempus-${local.environment}"
  glue_catalog_role_arn                     = local.environment_configuration.ap_data_glue_catalog_role
  glue_destination_bucket                   = local.environment == "production" ? "mojap-data-production-cica-dms-ingress-production" : ""
  metadata_generator_allowed_triggers = {
    EventBridge = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.metadata_generator.arn
    }
  }
}
