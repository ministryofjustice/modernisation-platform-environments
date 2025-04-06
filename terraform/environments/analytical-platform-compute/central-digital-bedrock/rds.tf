resource "aws_db_subnet_group" "vector_db_subnet_group" {
  name        = "bedrock-vector-db-subnet-group-${random_string.vector_db_suffix.result}"
  description = "Data subnets for Bedrock Vector database"
  subnet_ids  = data.aws_subnets.shared-data.ids

  tags = local.tags
}

module "vector_db" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier = "bedrock-vector-db-${random_string.vector_db_suffix.result}"

  engine               = "postgres"
  engine_version       = "17"
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = "db.t3.medium"

  ca_cert_identifier = "rds-ca-rsa2048-g1"

  storage_type          = "gp3"
  allocated_storage     = 100
  max_allocated_storage = 500

  multi_az               = local.is-production
  db_subnet_group_name   = aws_db_subnet_group.vector_db_subnet_group.name
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  username                            = "bedrock_${random_string.vector_db_username.result}"
  db_name                             = "vectordb"
  manage_master_user_password         = false
  password                            = random_password.vector_db.result
  iam_database_authentication_enabled = true
  kms_key_id                          = aws_kms_key.vector_db_kms.arn

  create_db_parameter_group       = true
  parameter_group_use_name_prefix = true
  parameter_group_name            = "bedrock-vector-db-params"
  parameter_group_description     = "Parameter group for PostgreSQL 17 with pgvector extension"

  parameters = [
    {
      name         = "rds.force_ssl"
      value        = 1
      apply_method = "pending-reboot"
    },
    {
      name         = "shared_preload_libraries"
      value        = "pg_stat_statements,pg_tle"
      apply_method = "immediate"
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
  deletion_protection     = local.is-production

  performance_insights_enabled = true

  create_monitoring_role          = true
  monitoring_role_use_name_prefix = true
  monitoring_role_name            = "bedrock-vector-db-monitoring"
  monitoring_role_description     = "Enhanced Monitoring for Bedrock Vector Database"
  monitoring_interval             = 30
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot = !local.is-production

  tags = local.tags
}
