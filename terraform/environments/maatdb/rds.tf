# This calls a custom RDS module to create a single RDS instance with option & parameter groups & multi-az and perf insights engabled.
# Also includes secrets manager storage for the randomised password that is (TO BE DONE) cycled periodically.

locals {
  rds_kms_key_arn = data.aws_kms_key.rds_shared.arn
}

module "rds" {

  source                                = "./modules/rds"
  application_name                      = upper(local.application_name)
  identifier_name                       = local.application_name
  environment                           = local.environment
  region                                = local.application_data.accounts[local.environment].region
  port                                  = local.application_data.accounts[local.environment].port
  allocated_storage                     = local.application_data.accounts[local.environment].allocated_storage
  engine                                = local.application_data.accounts[local.environment].engine
  engine_version                        = local.application_data.accounts[local.environment].engine_version
  instance_class                        = local.application_data.accounts[local.environment].instance_class
  allow_major_version_upgrade           = local.application_data.accounts[local.environment].allow_major_version_upgrade
  auto_minor_version_upgrade            = local.application_data.accounts[local.environment].auto_minor_version_upgrade
  storage_type                          = local.application_data.accounts[local.environment].storage_type
  iops                                  = local.application_data.accounts[local.environment].iops
  backup_retention_period               = local.application_data.accounts[local.environment].backup_retention_period
  backup_window                         = local.application_data.accounts[local.environment].backup_window
  maintenance_window                    = local.application_data.accounts[local.environment].maintenance_window
  character_set_name                    = local.application_data.accounts[local.environment].character_set_name
  multi_az                              = local.application_data.accounts[local.environment].multi_az
  username                              = local.application_data.accounts[local.environment].username
  db_password_rotation_period           = local.application_data.accounts[local.environment].db_password_rotation_period
  license_model                         = local.application_data.accounts[local.environment].license_model
  performance_insights_enabled          = local.application_data.accounts[local.environment].performance_insights_enabled
  performance_insights_retention_period = local.application_data.accounts[local.environment].performance_insights_retention_period
  snapshot_arn                          = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id, local.application_data.accounts[local.environment].snapshot_arn)
  deletion_protection                   = local.application_data.accounts[local.environment].deletion_protection
  cloud_platform_cidr                   = local.application_data.accounts[local.environment].cloud_platform_cidr
  vpc_shared_id                         = data.aws_vpc.shared.id
  vpc_shared_cidr                       = data.aws_vpc.shared.cidr_block
  vpc_subnet_a_id                       = data.aws_subnet.data_subnets_a.id
  vpc_subnet_b_id                       = data.aws_subnet.data_subnets_b.id
  vpc_subnet_c_id                       = data.aws_subnet.data_subnets_c.id
  bastion_security_group_id             = module.bastion_linux.bastion_security_group
  ecs_cluster_sec_group_id              = "${local.environment_management.account_ids["maat-${local.environment}"]}/${local.application_data.accounts[local.environment].ecs_cluster_sec_group_id}"
  mlra_ecs_cluster_sec_group_id         = "${local.environment_management.account_ids["mlra-${local.environment}"]}/${local.application_data.accounts[local.environment].mlra_ecs_cluster_sec_group_id}"
  mojfin_sec_group_id                   = local.application_data.accounts[local.environment].mojfin_sec_group_id
  hub20_sec_group_id                    = local.build_hub_integration ? "${local.environment_management.account_ids["laa-enterprise-service-bus-${local.environment}"]}/${local.application_data.accounts[local.environment].hub20_sec_group_id}" : ""
  hub20_s3_bucket                       = local.build_hub_integration ? local.application_data.accounts[local.environment].hub20_s3_bucket : ""
  kms_key_arn                           = local.rds_kms_key_arn

  tags = local.tags
}