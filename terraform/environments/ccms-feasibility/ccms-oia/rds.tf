module "rds" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b08a04f9346b56b005fdff6fcd595dc04a60fb8a
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/rds-instance?ref=b08a04f9346b56b005fdff6fcd595dc04a60fb8a"

  name           = "${local.component_name}-${local.env_label}-db"
  engine         = "mysql"
  engine_version = "8.0.40"

  instance_class    = local.application_data.accounts[local.environment].db_instance_type
  allocated_storage = local.application_data.accounts[local.environment].db_storage_gb

  db_name  = "opahub"
  username = local.application_data.accounts[local.environment].db_user
  password = jsondecode(data.aws_secretsmanager_secret_version.opahub.secret_string)["db_password"]
  port     = 3306

  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = data.aws_subnets.shared-data.ids
  kms_key_id             = data.aws_kms_key.rds_shared.arn

  deletion_protection    = local.application_data.accounts[local.environment].db_deletion_protection
  skip_final_snapshot    = true
  log_retention_days     = local.application_data.accounts[local.environment].db_log_retention_days
  cloudwatch_log_exports = ["error", "slowquery"]

  tags = local.tags
}
