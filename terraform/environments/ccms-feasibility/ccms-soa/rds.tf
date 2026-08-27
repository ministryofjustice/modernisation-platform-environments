# EDRMS's own TDS Oracle RDS instance
data "aws_db_instance" "edrms_tds" {
  db_instance_identifier = "ccms-edrms-${local.env_label}-tds"
}

module "rds" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b63bde8
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/rds?ref=b63bde8"

  name                 = "${local.component_name}-${local.env_label}-soa"
  engine               = "oracle-ee"
  engine_version       = "19.0.0.0.ru-2026-04.rur-2026-04.r1"
  major_engine_version = "19"

  instance_class    = local.application_data.accounts[local.environment].soa_db_instance_type
  allocated_storage = local.application_data.accounts[local.environment].soa_db_storage_gb

  db_name  = "SOADB"
  username = local.application_data.accounts[local.environment].soa_db_user
  password = jsondecode(data.aws_secretsmanager_secret_version.soa.secret_string)["soa_rds_admin_user_password"]
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

  deletion_protection    = local.application_data.accounts[local.environment].soa_db_deletion_protection
  skip_final_snapshot    = true
  log_retention_days     = local.application_data.accounts[local.environment].db_log_retention_days
  cloudwatch_log_exports = ["alert", "audit", "listener"]

  tags = local.tags
}
