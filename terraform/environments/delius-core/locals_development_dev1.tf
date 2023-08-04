# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  network_config_dev = {
    shared_vpc_cidr                = data.aws_vpc.shared.cidr_block
    private_subnet_ids             = data.aws_subnets.shared-private.ids
    route53_inner_zone_info        = data.aws_route53_zone.inner
    route53_network_services_zone  = data.aws_route53_zone.network-services
    route53_external_zone          = data.aws_route53_zone.external
    migration_environment_vpc_cidr = "10.161.20.0/22"
    general_shared_kms_key_arn     = data.aws_kms_key.general_shared.arn
    shared_vpc_id                  = data.aws_vpc.shared.id
  }

  ldap_config_dev = {
    name                        = try(local.ldap_config_lower_environments.name, "ldap")
    migration_source_account_id = local.ldap_config_lower_environments.migration_source_account_id
    migration_lambda_role       = local.ldap_config_lower_environments.migration_lambda_role
    efs_throughput_mode         = local.ldap_config_lower_environments.efs_throughput_mode
    efs_provisioned_throughput  = local.ldap_config_lower_environments.efs_provisioned_throughput
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
  }

  db_config_dev = {
    name     = try(local.db_config_lower_environments.name, "db")
    ami_name = local.db_config_lower_environments.ami_name
  }

  weblogic_config_dev = {
    name                          = try(local.weblogic_config_lower_environments.name, "weblogic")
    frontend_service_name         = try(local.weblogic_config_lower_environments.frontend_service_name, "weblogic")
    frontend_fully_qualified_name = try(local.weblogic_config_lower_environments.frontend_fully_qualified_name, "${local.application_name}-${local.frontend_service_name}")
    frontend_image_tag            = try(local.weblogic_config_lower_environments.frontend_image_tag, "5.7.6")
    frontend_container_port       = try(local.weblogic_config_lower_environments.frontend_container_port, 8080)
    frontend_url_suffix           = try(local.weblogic_config_lower_environments.frontend_url_suffix, "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk")
    db_service_name               = "testing-db"
    db_fully_qualified_name       = "${local.application_name}-${local.db_service_name}"
    db_image_tag                  = "5.7.4"
    db_port                       = 1521
    db_name                       = "MODNDA"
  }

  delius_db_container_config = {
    image_tag            = "5.7.4"
    image_name           = "delius-core-testing-db"
    fully_qualified_name = "${local.application_name}-${local.db_service_name}"
    db_port              = 1521
    db_name              = "MODNDA"
  }
}
