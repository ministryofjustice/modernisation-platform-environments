locals {
  db_name      = "vcms"
  db_root_user = "vcms"
}

data "aws_db_snapshot" "shared_snapshot" {
  db_snapshot_identifier = "arn:aws:rds:eu-west-2:356676313489:snapshot:rds-vcmsdev-db-backup-2025-09-26-14-04-mpcp"
  include_shared         = true
}

resource "aws_db_instance" "mariadb" {
  allocated_storage      = 200
  db_name                = local.db_name
  engine                 = "mariadb"
  engine_version         = "10.5.27"
  instance_class         = "db.t4g.medium"
  username               = local.db_root_user
  password               = random_id.db_password.b64_url
  parameter_group_name   = aws_db_parameter_group.vcms-10-5.name
  db_subnet_group_name   = aws_db_subnet_group.mariadb.name
  vpc_security_group_ids = [aws_security_group.mariadb.id]
  skip_final_snapshot    = true
  snapshot_identifier    = data.aws_db_snapshot.shared_snapshot.id
}

resource "random_id" "db_password" {
  byte_length = 16
}

resource "aws_ssm_parameter" "db_password" {
  name        = "${local.db_name}-db-root-password"
  description = "The parameter description"
  type        = "SecureString"
  value       = random_id.db_password.b64_url
  tags        = local.tags
  overwrite   = true
}

resource "aws_db_parameter_group" "vcms-10-5" {
  name   = "${local.db_name}-10-5"
  family = "mariadb10.5"
  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  parameter {
    name  = "general_log"
    value = "1"
  }
  parameter {
    name  = "log_output"
    value = "FILE"
  }
  tags = local.tags
}

resource "aws_db_subnet_group" "mariadb" {
  name       = "mariadb-subnet-group"
  subnet_ids = local.account_config.private_subnet_ids

  tags = local.tags
}


resource "aws_security_group" "mariadb" {
  name        = "rds-mariadb-sg"
  description = "SG for mariadb"
  vpc_id      = local.account_info.vpc_id

  ingress {
    description     = "MySQL from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

