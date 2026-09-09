# S3 target

resource "aws_s3_bucket" "dms_target" {
  bucket_prefix = "dms-core-test-"

  # DMS writes objects into this bucket. The bucket belongs exclusively to
  # this disposable integration-test harness, so allow Terraform to remove
  # the contents during teardown.
  force_destroy = true

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-test-target"
      Purpose = "DMS integration test target"
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dms_target" {
  bucket = aws_s3_bucket.dms_target.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dms_target" {
  bucket = aws_s3_bucket.dms_target.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "dms_target" {
  bucket = aws_s3_bucket.dms_target.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# PostgreSQL networking

resource "aws_db_subnet_group" "postgres" {
  name_prefix = "${var.name}-"
  subnet_ids  = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-postgres"
      Purpose = "DMS integration test source"
    }
  )
}

# PostgreSQL configuration

resource "aws_db_parameter_group" "postgres" {
  name_prefix = "${var.name}-"
  family      = var.postgres_parameter_group_family

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-postgres"
      Purpose = "DMS integration test CDC"
    }
  )
}

resource "aws_db_instance" "postgres" {
  identifier_prefix = "${var.name}-"

  engine         = "postgres"
  engine_version = var.postgres_engine_version

  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage

  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.database_name
  username = var.database_username
  port     = var.postgres_port

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  parameter_group_name = aws_db_parameter_group.postgres.name

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1

  deletion_protection = false
  skip_final_snapshot = true

  apply_immediately          = true
  auto_minor_version_upgrade = true

  performance_insights_enabled = false
  monitoring_interval          = 0

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-postgres"
      Purpose = "DMS integration test source"
    }
  )
}

# Networking Boundary

resource "aws_security_group" "dms_client" {
  name_prefix = "${var.name}-dms-client-"
  description = "Attached to DMS to permit access to the integration-test PostgreSQL source."
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-dms-client"
      Purpose = "DMS integration test connectivity"
    }
  )
}

resource "aws_security_group" "postgres" {
  name_prefix = "${var.name}-postgres-"
  description = "Restricts access to the integration-test PostgreSQL source."
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-postgres"
      Purpose = "DMS integration test source"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_dms" {
  security_group_id = aws_security_group.postgres.id

  referenced_security_group_id = aws_security_group.dms_client.id

  from_port   = var.postgres_port
  to_port     = var.postgres_port
  ip_protocol = "tcp"

  description = "Allow PostgreSQL connections from the DMS replication instance."
}
