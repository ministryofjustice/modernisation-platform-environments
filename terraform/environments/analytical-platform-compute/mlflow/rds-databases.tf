module "mlflow_auth_rds" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/rds/aws"
  version = "6.12.0"

  identifier = "mlflow-auth"

  engine               = "postgres"
  engine_version       = "16"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.t4g.micro"

  ca_cert_identifier = "rds-ca-rsa2048-g1"

  storage_type          = "gp2" # Has to be bigger than 400 to use gp3 "You can't specify IOPS or storage throughput for engine postgres and a storage size less than 400."
  allocated_storage     = 64
  max_allocated_storage = 256

  multi_az               = true
  db_subnet_group_name   = data.aws_db_subnet_group.apc.name
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  username                    = "mlflowauth"
  db_name                     = "mlflowauth"
  manage_master_user_password = false
  password                    = random_password.mlflow_auth_rds.result
  kms_key_id                  = module.mlflow_auth_rds_kms.key_arn

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
  monitoring_role_name            = "mlflow-auth-rds-monitoring"
  monitoring_role_description     = "Enhanced Monitoring for MLflow Auth RDS"
  monitoring_interval             = 30
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot = true

  tags = local.tags
}

module "mlflow_rds" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/rds/aws"
  version = "6.12.0"

  identifier = "mlflow"

  engine               = "postgres"
  engine_version       = "16"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.t4g.medium"

  ca_cert_identifier = "rds-ca-rsa2048-g1"

  storage_type          = "gp2" # Has to be bigger than 400 to use gp3 "You can't specify IOPS or storage throughput for engine postgres and a storage size less than 400."
  allocated_storage     = 64
  max_allocated_storage = 256

  multi_az               = true
  db_subnet_group_name   = data.aws_db_subnet_group.apc.name
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  username                    = "mlflow"
  db_name                     = "mlflow"
  manage_master_user_password = false
  password                    = random_password.mlflow_rds.result
  kms_key_id                  = module.mlflow_rds_kms.key_arn

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
  monitoring_role_name            = "mlflow-rds-monitoring"
  monitoring_role_description     = "Enhanced Monitoring for MLflow RDS"
  monitoring_interval             = 30
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot = true

  tags = local.tags
}
