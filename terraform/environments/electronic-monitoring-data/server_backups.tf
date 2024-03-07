#------------------------------------------------------------------------------
# Secret generation for database access.
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "db_password" {
  name = "db_password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.random_password.result
}

resource "random_password" "random_password" {
  length  = 32
  special = false
}

#------------------------------------------------------------------------------
# RDS SQL server 2022 database
#------------------------------------------------------------------------------
resource "aws_db_instance" "database_2022" {
#   count = local.is-production ? 1 : 0

  identifier    = "database-v2022"
  license_model = "license-included"
  username      = "admin"
  password      = aws_secretsmanager_secret_version.db_password.secret_string

  engine         = "sqlserver-se"
  engine_version = "16.00.4105.2.v1"
  instance_class = "db.m5.large"

  storage_type          = "gp2"
  allocated_storage     = 100
  max_allocated_storage = 5000
  storage_encrypted     = true

  multi_az = false

  db_subnet_group_name   = aws_db_subnet_group.db.id
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = true
  port                   = 1433

  auto_minor_version_upgrade = true
  skip_final_snapshot        = true
  maintenance_window         = "Mon:00:00-Mon:03:00"
  deletion_protection        = false

  option_group_name = aws_db_option_group.sqlserver_backup_restore_2022.name

  iam_database_authentication_enabled = false

  tags = local.tags
}

#------------------------------------------------------------------------------
# Security group and subnets for accessing database
#------------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "database-security-group"
  description = "Allow DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "db_ipv4" {
  security_group_id = aws_security_group.db.id
  description       = "Default SQL Server port 1433"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433

  # fy nhy
  cidr_ipv4 = "46.69.144.146/32"
}

resource "aws_vpc_security_group_ingress_rule" "db_ipv4_madetech" {
  security_group_id = aws_security_group.db.id
  description       = "madetech ip"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433

  # madetech
  cidr_ipv4 = "79.173.131.202/32"
}

resource "aws_db_subnet_group" "db" {
  name       = "db-subnet-group"
  subnet_ids = data.aws_subnets.shared-public.ids
  
  tags = local.tags
}

#------------------------------------------------------------------------------
# Option group configuration for database
#------------------------------------------------------------------------------
resource "aws_db_option_group" "sqlserver_backup_restore_2022" {
  name                     = "sqlserver-v2022"
  option_group_description = "SQL server backup restoration using engine 16.x"
  engine_name              = "sqlserver-se"
  major_engine_version     = "16.00"

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.s3_database_backups_role.arn
    }
  }

  tags = local.tags
}

#------------------------------------------------------------------------------
# Database access policy to data store bucket
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "rds-s3-access-policy" {
  version = "2012-10-17"
  statement {
    sid    = ""
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

resource "aws_iam_role" "s3_database_backups_role" {
  name               = "s3-database-backups-role"
  assume_role_policy = data.aws_iam_policy_document.rds-s3-access-policy.json

  tags = local.tags
}

data "aws_iam_policy_document" "rds_data_store_access" {
  statement {
    sid    = "AllowListAndDecryptDataStore"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
        aws_s3_bucket.data_store.arn,
    ]
  }
  statement {
    sid    = "AllowReadDataStore"
    effect = "Allow"
    actions = [
      "s3:GetObjectMetaData",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
    ]
    resources = [
        "${aws_s3_bucket.data_store.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "this_transfer_workflow" {
  role   = aws_iam_role.s3_database_backups_role.name
  policy = data.aws_iam_policy_document.rds_data_store_access.json
}
