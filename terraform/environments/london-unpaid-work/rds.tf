locals {
  create_rds = local.is-development && local.account_config.rds_enabled
}

resource "aws_db_subnet_group" "database" {
  count = local.create_rds ? 1 : 0

  name       = "${local.application_name}-${local.environment}-database"
  subnet_ids = data.aws_subnets.shared-data.ids

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-database"
    }
  )
}

resource "aws_security_group" "database" {
  count = local.create_rds ? 1 : 0

  name        = "${local.application_name}-${local.environment}-database"
  description = "Controls access to the London Unpaid Work database"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-database"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "database_from_windows" {
  count = local.create_rds ? 1 : 0

  description                  = "Allow SQL Server access from London Unpaid Work Windows servers"
  security_group_id            = aws_security_group.database[0].id
  referenced_security_group_id = module.baseline.security_groups["ec2-windows"].id
  ip_protocol                  = "tcp"
  from_port                    = local.account_config.db_port
  to_port                      = local.account_config.db_port
}

resource "aws_db_instance" "database" {
  count = local.create_rds ? 1 : 0

  identifier = local.account_config.db_identifier

  engine               = local.account_config.db_engine
  engine_version       = local.account_config.db_engine_version
  instance_class       = local.account_config.db_instance_class
  license_model        = "license-included"
  parameter_group_name = "default.sqlserver-se-15.0"
  option_group_name    = aws_db_option_group.database[0].name

  username                    = local.account_config.db_user
  manage_master_user_password = true
  port                        = local.account_config.db_port

  allocated_storage     = local.account_config.db_allocated_storage
  max_allocated_storage = local.account_config.db_max_allocated_storage
  storage_type          = local.account_config.db_storage_type
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.database[0].name
  vpc_security_group_ids = [aws_security_group.database[0].id]
  publicly_accessible    = false
  multi_az               = local.account_config.db_multi_az

  backup_retention_period = local.account_config.db_backup_retention_period
  skip_final_snapshot     = local.account_config.db_skip_final_snapshot
  deletion_protection     = local.account_config.db_deletion_protection

  auto_minor_version_upgrade  = local.account_config.db_auto_minor_version_upgrade
  allow_major_version_upgrade = local.account_config.db_allow_major_version_upgrade
  apply_immediately           = local.account_config.db_apply_immediately

  copy_tags_to_snapshot = true

  tags = merge(
    local.tags,
    {
      Name = local.account_config.db_identifier
    }
  )
}

data "aws_iam_policy_document" "rds_artifacts_assume_role" {
  count = local.create_rds ? 1 : 0

  statement {
    sid    = "AllowRDSAssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "rds.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "rds_artifacts" {
  count = local.create_rds ? 1 : 0

  name               = "${local.application_name}-${local.environment}-rds-artifacts"
  description        = "Allows London Unpaid Work RDS to read database backups from the artifacts bucket"
  assume_role_policy = data.aws_iam_policy_document.rds_artifacts_assume_role[0].json

  tags = local.tags
}

data "aws_iam_policy_document" "rds_artifacts" {
  count = local.create_rds ? 1 : 0

  statement {
    sid    = "ListArtifactsBucket"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      module.baseline.s3_buckets["artifacts-bucket"].bucket.arn,
    ]
  }

  statement {
    sid    = "ReadDatabaseBackups"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "${module.baseline.s3_buckets["artifacts-bucket"].bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "rds_artifacts" {
  count = local.create_rds ? 1 : 0

  name   = "${local.application_name}-${local.environment}-rds-artifacts"
  role   = aws_iam_role.rds_artifacts[0].id
  policy = data.aws_iam_policy_document.rds_artifacts[0].json
}

resource "aws_db_option_group" "database" {
  count = local.create_rds ? 1 : 0

  name                     = "${local.application_name}-${local.environment}-database"
  option_group_description = "SQL Server native backup and restore from the London Unpaid Work artifacts bucket"
  engine_name              = "sqlserver-se"
  major_engine_version     = "15.00"

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.rds_artifacts[0].arn
    }
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy.rds_artifacts,
  ]
}