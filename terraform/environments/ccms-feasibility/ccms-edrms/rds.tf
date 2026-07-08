module "rds" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/29884f0212632a650344ec73811e0cc2844c1e73
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/rds-instance?ref=29884f0212632a650344ec73811e0cc2844c1e73"

  name                 = "${local.component_name}-${local.env_label}-tds"
  engine               = "oracle-se2"
  engine_version       = "19.0.0.0.ru-2024-01.rur-2024-01.r1"
  major_engine_version = "19"

  instance_class    = local.application_data.accounts[local.environment].tds_db_instance_type
  allocated_storage = local.application_data.accounts[local.environment].tds_db_storage_gb
  iops              = local.application_data.accounts[local.environment].tds_db_iops
  multi_az          = local.application_data.accounts[local.environment].tds_db_multi_az

  db_name  = "EDRMSTDS"
  username = local.application_data.accounts[local.environment].tds_db_user
  password = jsondecode(data.aws_secretsmanager_secret_version.edrms.secret_string)["spring_datasource_password"]
  port     = 1521

  character_set_name = "AL32UTF8"
  license_model      = "bring-your-own-license"

  options = [
    {
      option_name = "S3_INTEGRATION"
      port        = 0
      version     = "1.0"
    }
  ]

  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = data.aws_subnets.shared-data.ids
  kms_key_id             = data.aws_kms_key.rds_shared.arn

  deletion_protection    = local.application_data.accounts[local.environment].tds_db_deletion_protection
  skip_final_snapshot    = true
  log_retention_days     = local.application_data.accounts[local.environment].db_log_retention_days
  cloudwatch_log_exports = ["alert", "audit", "listener"]

  tags = local.tags
}
