resource "random_password" "cst_db" {
  length  = 32
  special = false
}

resource "aws_security_group" "cst_rds_sc" {
  name        = "ecs security group"
  description = "control access to the rds"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS for the Global Protect VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["35.176.93.186/32"]
  }
}

resource "aws_db_subnet_group" "cst_database" {
  name       = "${local.application_name}-tds-subnet-group"
  subnet_ids = data.aws_subnets.shared-data.ids
}

resource "aws_db_instance" "cst_db" {
  identifier              = "cst-postgres-db"
  allocated_storage       = 20
  monitoring_interval     = 5
  monitoring_role_arn     = aws_iam_role.rds_enhanced_monitoring[0].arn
  instance_class          = "db.t3.micro"
  engine                  = "postgres"
  engine_version          = "16"
  db_subnet_group_name    = aws_db_subnet_group.cst_database.name
  username                = "postgresadmin"
  password                = random_password.cst_db.result
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = true
  backup_retention_period = 1
  vpc_security_group_ids  = [aws_security_group.cst_rds_sc.id]
  apply_immediately       = true
  auto_minor_version_upgrade = true
  multi_az                = true
  performance_insights_enabled = true
  iam_database_authentication_enabled = true
  storage_encrypted       = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  copy_tags_to_snapshot   = true
  performance_insights_kms_key_id = var.performance_insights_kms_key_id
  parameter_group_name        = aws_db_parameter_group.cst_db.name
  tags = {
    Name = "PostgresLatest"
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring[0].json
  count              = 1
  name_prefix        = "rds-enhanced-monitoring"
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  count = 1

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_db_parameter_group" "cst_db" {
  name = "cst-postgres-db"
  family      = "postgres16"

  parameter {
    name="log_statement"
    value="all"
  }

  parameter {
    name="log_min_duration_statement"
    value="1"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.cst_db.endpoint
}

output "rds_master_username" {
  value = aws_db_instance.cst_db.username
}

output "rds_master_password" {
  value = random_password.cst_db.result
  sensitive = true
}