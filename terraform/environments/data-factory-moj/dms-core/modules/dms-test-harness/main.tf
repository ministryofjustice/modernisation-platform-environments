# S3 target

resource "aws_s3_bucket" "dms_target" {
  #checkov:skip=CKV_AWS_18: Access logging is unnecessary for this disposable development integration-test bucket.
  #checkov:skip=CKV_AWS_144: Cross-region replication is unnecessary for disposable development integration-test data.
  #checkov:skip=CKV2_AWS_62: Event notifications are outside the scope of this DMS source-to-S3 integration test.

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
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
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

resource "aws_s3_bucket_versioning" "dms_target" {
  bucket = aws_s3_bucket.dms_target.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "dms_target" {
  bucket = aws_s3_bucket.dms_target.id

  rule {
    id     = "expire-integration-test-data"
    status = "Enabled"

    filter {}

    expiration {
      days = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
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

  parameter {
    name         = "rds.force_ssl"
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
  #checkov:skip=CKV_AWS_161: DMS authenticates to this temporary PostgreSQL source using the RDS-managed Secrets Manager credential.
  #checkov:skip=CKV_AWS_293: This development-only integration database is intentionally disposable and must be removable by Terraform.
  #checkov:skip=CKV_AWS_118: Enhanced monitoring is unnecessary for this short-lived development integration database.
  #checkov:skip=CKV_AWS_353: Performance Insights is unnecessary for this short-lived development integration database.
  #checkov:skip=CKV_AWS_157: Multi-AZ availability is outside the scope of this disposable DMS integration test.
  #checkov:skip=CKV2_AWS_60: This disposable database deliberately skips final snapshots, so snapshot tag propagation is not applicable.

  identifier_prefix = "${var.name}-"

  engine         = "postgres"
  engine_version = var.postgres_engine_version

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.database_name
  username = var.database_username
  port     = var.postgres_port

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  parameter_group_name = aws_db_parameter_group.postgres.name

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

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
  #checkov:skip=CKV2_AWS_5: This security group is passed across the module boundary and attached to the DMS replication instance by dms-core.

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
