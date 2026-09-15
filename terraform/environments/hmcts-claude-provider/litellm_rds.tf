resource "aws_security_group" "litellm_db" {
  name_prefix = "litellm-db-"
  description = "LiteLLM gateway database"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "litellm_db_from_tasks" {
  security_group_id            = aws_security_group.litellm_db.id
  description                  = "Postgres from LiteLLM tasks"
  referenced_security_group_id = aws_security_group.litellm_task.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_db_subnet_group" "litellm" {
  name       = "litellm-gateway"
  subnet_ids = data.aws_subnets.shared-data.ids
}

resource "aws_db_parameter_group" "litellm" {
  name   = "litellm-gateway-postgres16"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_db_instance" "litellm" {
  #checkov:skip=CKV_AWS_157: "Multi-AZ not required in development"
  #checkov:skip=CKV_AWS_118: "Enhanced monitoring not required"
  #checkov:skip=CKV_AWS_161: "IAM database authentication not used, LiteLLM authenticates with a password from Secrets Manager"
  #checkov:skip=CKV_AWS_353: "Performance insights not required"
  #checkov:skip=CKV2_AWS_30: "Query logging not required"
  identifier     = "litellm-gateway"
  engine         = "postgres"
  engine_version = "16"
  instance_class = local.application_data.accounts[local.environment].litellm_db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = data.aws_kms_key.rds_shared.arn

  db_name  = "litellm"
  username = "litellm"
  password = random_password.litellm_db.result

  db_subnet_group_name   = aws_db_subnet_group.litellm.name
  vpc_security_group_ids = [aws_security_group.litellm_db.id]
  parameter_group_name   = aws_db_parameter_group.litellm.name
  publicly_accessible    = false
  multi_az               = local.is-production

  backup_retention_period         = 7
  copy_tags_to_snapshot           = true
  auto_minor_version_upgrade      = true
  apply_immediately               = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  deletion_protection             = true
  skip_final_snapshot             = false
  final_snapshot_identifier       = "litellm-gateway-final"
}
