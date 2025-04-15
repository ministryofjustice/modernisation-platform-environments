locals {
    short_resource_name = "tariff-${local.environment}"
    resource_name = "cica-ap-${local.short_resource_name}"
}

module "cica_dms_tariff_dms_implementation" {

    source      = "../modules/dms"
    vpc_id      = data.aws_vpc.connected_vpc.id
    environment = local.environment

    db          = local.short_resource_name

    dms_replication_instance = {
        replication_instance_id    = local.resource_name
        subnet_cidrs               = local.environment_configuration.connected_vpc_private_subnets
        subnet_group_name          = local.resource_name
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
        engine_name                 = "oracle"
        secrets_manager_arn         = module.cica_dms_tariff_database_credentials.secret_arn
        secrets_manager_kms_arn     = module.cica_dms_credentials_kms.key_arn
        sid                         = local.environment_configuration.source_database_sid
        cdc_start_time              = "2025-03-10T12:00:00Z"
    }
    dms_target_prefix = "cica_tariff"
    replication_task_id = {
      full_load = "${local.resource_name}-full-load"
    }
    dms_mapping_rules     = "./metadata/cica_tariff.json"
    output_bucket         = module.cica_dms_ingress_bucket.s3_bucket_id

    tags = local.tags

    create_premigration_assessement_resources = local.environment == "development" ? true : false
    write_metadata_to_glue_catalog            = true
    retry_failed_after_recreate_metadata      = false
    valid_files_mutable                       = true
    glue_catalog_account_id                   = local.environment_management.account_ids["analytical-platform-data-production"]
    glue_catalog_database_name                = "cica_tariff_${local.environment}"
    glue_catalog_role_arn                     = local.environment_configuration.ap_data_glue_catalog_role
    glue_destination_bucket                   = local.environment == "production" ? "mojap-data-production-cica-dms-ingress-production" : ""
}
