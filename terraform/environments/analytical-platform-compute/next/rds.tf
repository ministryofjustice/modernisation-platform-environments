module "rds" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  source  = "terraform-aws-modules/rds/aws"
  version = "6.12.0"

  identifier = local.component_name

  engine               = "postgres"
  engine_version       = "17"
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = "db.t4g.small"

  storage_type          = "gp2"
  allocated_storage     = 64
  max_allocated_storage = 256

  db_subnet_group_name   = data.aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.rds_security_group[0].security_group_id]

  username                    = local.db_dbuser
  db_name                     = local.db_dbname
  manage_master_user_password = false
  password                    = random_password.rds[0].result
  kms_key_id                  = module.rds_kms[0].key_arn

  parameters = [
    {
      name         = "rds.force_ssl"
      value        = 1
      apply_method = "pending-reboot"
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_hostname"
      value = 1
    },
    {
      name  = "log_connections"
      value = 1
    }
  ]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 7
  deletion_protection     = true

  performance_insights_enabled = true

  create_monitoring_role          = true
  monitoring_role_use_name_prefix = true
  monitoring_role_name            = "${local.component_name}-rds-monitoring"
  monitoring_role_description     = "Enhanced Monitoring for ${local.component_name} RDS"
  monitoring_interval             = 30
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot = true

  tags = local.tags
}
