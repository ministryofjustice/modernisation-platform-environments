# This calls a custom RDS module to create a single RDS instance with option & parameter groups & multi-az and perf insights engabled.
# Also includes secrets manager storage for the randomised password that is (TO BE DONE) cycled periodically.

module "rds" {
  source = "./modules/rds"

  application_name            = local.application_name
  identifier_name             = local.application_name
  environment                 = local.environment
  region                      = local.application_data.accounts[local.environment].region
  allocated_storage           = local.application_data.accounts[local.environment].allocated_storage
  engine                      = local.application_data.accounts[local.environment].engine
  engine_version              = local.application_data.accounts[local.environment].engine_version
  instance_class              = local.application_data.accounts[local.environment].instance_class
  allow_major_version_upgrade = local.application_data.accounts[local.environment].allow_major_version_upgrade
  auto_minor_version_upgrade  = local.application_data.accounts[local.environment].auto_minor_version_upgrade
  storage_type                = local.application_data.accounts[local.environment].storage_type
  backup_retention_period     = local.application_data.accounts[local.environment].backup_retention_period
  backup_window               = local.application_data.accounts[local.environment].backup_window
  maintenance_window          = local.application_data.accounts[local.environment].maintenance_window
  character_set_name          = local.application_data.accounts[local.environment].character_set_name
  availability_zone           = local.application_data.accounts[local.environment].availability_zone
  multi_az                    = local.application_data.accounts[local.environment].multi_az
  username                    = local.application_data.accounts[local.environment].username
  db_password_rotation_period = local.application_data.accounts[local.environment].db_password_rotation_period
  license_model               = local.application_data.accounts[local.environment].license_model
  lz_vpc_cidr                 = local.application_data.accounts[local.environment].lz_vpc_cidr
  deletion_protection         = local.application_data.accounts[local.environment].deletion_protection
  rds_snapshot_arn            = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id, local.application_data.accounts[local.environment].rds_snapshot_name)
  rds_kms_key_arn             = data.aws_kms_key.rds_shared.arn
  vpc_shared_id               = data.aws_vpc.shared.id
  vpc_shared_cidr             = data.aws_vpc.shared.cidr_block
  vpc_subnet_a_id             = data.aws_subnet.data_subnets_a.id
  vpc_subnet_b_id             = data.aws_subnet.data_subnets_b.id
  vpc_subnet_c_id             = data.aws_subnet.data_subnets_c.id
  tags                        = local.tags
}

resource "aws_route53_record" "oas-rds" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.inner.zone_id
  name     = "rds.${local.application_name}.${data.aws_route53_zone.inner.name}"
  type     = "CNAME"
  ttl      = 60
  records  = [module.rds.rds_endpoint]
}
