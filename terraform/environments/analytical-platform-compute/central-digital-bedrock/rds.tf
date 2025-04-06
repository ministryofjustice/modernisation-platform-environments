resource "aws_db_subnet_group" "vector_db_subnet_group" {
  name        = "bedrock-vector-db-subnet-group-${random_string.vector_db_suffix.result}"
  description = "Data subnets for Bedrock Vector database"
  subnet_ids  = data.aws_subnets.shared-data.ids

  tags = local.tags
}

module "vector_db" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 8.5.0"

  name                     = "bedrock-vector-db-${random_string.vector_db_suffix.result}"
  engine                   = "aurora-postgresql"
  engine_version           = "16.1"
  instance_class           = "db.t4g.medium"
  autoscaling_enabled      = true
  autoscaling_min_capacity = local.is-production ? 1 : 0 # I only want replicas in prod, not dev
  autoscaling_max_capacity = local.is-production ? 1 : 0 # I only want replicas in prod, not dev
  instances = {
    primary = {
      identifier = "bedrock-vector-db-primary-${random_string.vector_db_suffix.result}"
    }
  }


  vpc_id                 = data.aws_vpc.shared.id
  db_subnet_group_name   = aws_db_subnet_group.vector_db_subnet_group.name
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  database_name   = "vectordb"
  master_username = "bedrock_${random_string.vector_db_username.result}"
  master_password = random_password.vector_db.result

  storage_encrypted = true
  kms_key_id        = aws_kms_key.vector_db_kms.arn

  create_db_parameter_group         = true
  create_db_cluster_parameter_group = true

  db_parameter_group_use_name_prefix         = true
  db_cluster_parameter_group_use_name_prefix = true

  db_parameter_group_name                = "bedrock-vector-db-params"
  db_parameter_group_description         = "Instance parameter group for Aurora PostgreSQL 16"
  db_cluster_parameter_group_name        = "bedrock-vector-cluster-params"
  db_cluster_parameter_group_description = "Cluster parameter group for Aurora PostgreSQL 16"

  db_cluster_parameter_group_family = "aurora-postgresql16"
  db_cluster_parameter_group_parameters = [
    {
      name         = "shared_preload_libraries"
      value        = "pg_stat_statements,pg_tle,pgaudit"
      apply_method = "pending-reboot"
    },
    {
      name         = "rds.force_ssl"
      value        = "1"
      apply_method = "pending-reboot"
    }
  ]

  db_parameter_group_family = "aurora-postgresql16"
  db_parameter_group_parameters = [
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_hostname"
      value = "1"
    },
    {
      name  = "log_connections"
      value = "1"
    }
  ]

  monitoring_interval                 = 30
  iam_database_authentication_enabled = true
  create_monitoring_role              = true
  iam_role_name                       = "bedrock-vector-db-monitoring"
  iam_role_use_name_prefix            = true
  iam_role_description                = "Enhanced Monitoring for Bedrock Vector Database"

  apply_immediately            = false
  skip_final_snapshot          = !local.is-production
  deletion_protection          = local.is-production
  backup_retention_period      = 7
  preferred_maintenance_window = "Mon:00:00-Mon:03:00"
  preferred_backup_window      = "03:00-06:00"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = local.tags
}
