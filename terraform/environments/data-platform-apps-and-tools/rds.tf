module "datahub_rds" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "datahub"

  engine               = "postgres"
  engine_version       = "15"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = "db.r6g.xlarge"

  ca_cert_identifier = "rds-ca-rsa2048-g1"

  allocated_storage     = 128
  max_allocated_storage = 512

  multi_az               = true
  db_subnet_group_name   = data.aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [module.datahub_rds_security_group.security_group_id]

  username                    = "datahub"
  db_name                     = "datahub"
  manage_master_user_password = false
  password                    = random_password.datahub_rds.result
  kms_key_id                  = module.datahub_rds_kms.key_arn

  parameters = [
    {
      name  = "rds.force_ssl"
      value = 1
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

  apply_immediately = true

  performance_insights_enabled = true

  create_monitoring_role          = true
  monitoring_role_use_name_prefix = true
  monitoring_role_name            = "datahub-rds-monitoring"
  monitoring_role_description     = "Enhanced Monitoring for Datahub RDS"
  monitoring_interval             = 30
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot = true

  tags = local.tags
}