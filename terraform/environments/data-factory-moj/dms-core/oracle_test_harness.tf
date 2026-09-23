module "oracle_test_harness" {
  count = local.dms_core_enabled ? 1 : 0

  source = "./modules/oracle-test-harness"

  name = "${local.application_name}-${local.environment}-${local.component_name}"

  vpc_id     = data.aws_vpc.shared[0].id
  subnet_ids = data.aws_subnets.shared-data[0].ids

  kms_key_arn     = data.aws_kms_key.general_shared.arn
  rds_kms_key_arn = data.aws_kms_key.rds_shared.arn

  seed_image_uri = "${aws_ecr_repository.dms_seed[0].repository_url}:oracle-seed-v3"

  database_name     = "DMSTEST"
  database_username = "dms_admin"
  dms_username      = "DMS_USER"

  oracle_port                   = 1521
  oracle_engine_version         = "19"
  oracle_parameter_group_family = "oracle-se2-19"

  instance_class        = "db.m5.large"
  allocated_storage     = 20
  max_allocated_storage = 0

  archive_log_retention_hours = 24

  tags = local.tags
}
