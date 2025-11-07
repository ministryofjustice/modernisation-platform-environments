#------------------------------------------------------------------------------
# Secret generation for database access.
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "db_password" {
  count = local.is-production || local.is-development ? 1 : 0
  name  = "db_password"
  #checkov:skip=CKV_AWS_149
  #checkov:skip=CKV2_AWS_57
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count         = local.is-production || local.is-development ? 1 : 0
  secret_id     = aws_secretsmanager_secret.db_password[0].id
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
  count = local.is-production || local.is-development ? 1 : 0

  identifier    = "database-v2022"
  license_model = "license-included"
  username      = "admin"
  password      = aws_secretsmanager_secret_version.db_password[0].secret_string

  engine         = "sqlserver-se"
  engine_version = "16.00.4105.2.v1"
  instance_class = "db.m5.large"

  storage_type          = "gp2"
  allocated_storage     = 2500
  max_allocated_storage = 3000
  storage_encrypted     = true

  multi_az = false

  db_subnet_group_name   = aws_db_subnet_group.db[0].id
  vpc_security_group_ids = [aws_security_group.db[0].id]
  port                   = 1433

  auto_minor_version_upgrade = true
  skip_final_snapshot        = true
  maintenance_window         = "Mon:00:00-Mon:03:00"
  deletion_protection        = false

  option_group_name = aws_db_option_group.sqlserver_backup_restore_2022[0].name

  iam_database_authentication_enabled = false

  apply_immediately = true

  tags = local.tags
  #checkov:skip=CKV_AWS_354
  #checkov:skip=CKV_AWS_157
  #checkov:skip=CKV_AWS_118
  #checkov:skip=CKV_AWS_353
  #checkov:skip=CKV_AWS_293
  #checkov:skip=CKV_AWS_129
  #checkov:skip=CKV2_AWS_60
}

#------------------------------------------------------------------------------
# Security group and subnets for accessing database
#------------------------------------------------------------------------------
resource "aws_security_group" "db" {
  count       = local.is-production || local.is-development ? 1 : 0
  name        = "database-security-group"
  description = "Allow DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "db_ipv4_mp" {
  count = local.is-production || local.is-development ? 1 : 0

  security_group_id = aws_security_group.db[0].id
  description       = "Default SQL Server port 1433 access for Matt Price"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433

  cidr_ipv4 = "46.69.144.146/32"
}

resource "aws_vpc_security_group_ingress_rule" "db_ipv4_mh" {
  count = local.is-development ? 1 : 0

  security_group_id = aws_security_group.db[0].id
  description       = "Default SQL Server port 1433 access for Matt Heery"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433

  cidr_ipv4 = "152.37.111.98/32"
}
resource "aws_vpc_security_group_ingress_rule" "db_ipv4_pf" {
  count = local.is-production || local.is-development ? 1 : 0

  security_group_id = aws_security_group.db[0].id
  description       = "PF ip"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433

  cidr_ipv4 = "213.121.161.124/32"
}

resource "aws_vpc_security_group_ingress_rule" "db_ipv4_mk" {
  count = local.is-production || local.is-development ? 1 : 0

  security_group_id = aws_security_group.db[0].id
  description       = "Default SQL Server port 1433 access for MK"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433

  cidr_ipv4 = "80.195.205.143/32"
}

resource "aws_vpc_security_group_ingress_rule" "db_ipv4_lb" {
  count = local.is-development ? 1 : 0

  security_group_id = aws_security_group.db[0].id
  description       = "Default SQL Server port 1433 access for Lee Broadhurst"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433

  cidr_ipv4 = "209.35.83.77/32"
}

resource "aws_db_subnet_group" "db" {
  count      = local.is-production || local.is-development ? 1 : 0
  name       = "db-subnet-group"
  subnet_ids = data.aws_subnets.shared-public.ids

  tags = local.tags
}

# -----------------------------------------------------------------------
# Rule necessary for at least one security group to open all egress ports
# -----------------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "rds_egress_all" {
  count = local.is-production || local.is-development ? 1 : 0

  security_group_id            = aws_security_group.db[0].id
  referenced_security_group_id = aws_security_group.db[0].id
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65535
  description                  = "RDS Database -----[all ports]-----+ RDS Database"
}

#------------------------------------------------------------------------------
# Option group configuration for database
#------------------------------------------------------------------------------
resource "aws_db_option_group" "sqlserver_backup_restore_2022" {
  count                    = local.is-production || local.is-development ? 1 : 0
  name                     = "sqlserver-v2022"
  option_group_description = "SQL server backup restoration using engine 16.x"
  engine_name              = "sqlserver-se"
  major_engine_version     = "16.00"

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.s3_database_backups_role[0].arn
    }
  }

  tags = local.tags
}

#------------------------------------------------------------------------------
# Database access policy to data store bucket
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "rds-s3-access-policy" {
  count   = local.is-production || local.is-development ? 1 : 0
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
  count              = local.is-production || local.is-development ? 1 : 0
  name               = "s3-database-backups-role"
  assume_role_policy = data.aws_iam_policy_document.rds-s3-access-policy[0].json

  tags = local.tags
}

data "aws_iam_policy_document" "rds_data_store_access" {
  count = local.is-production || local.is-development ? 1 : 0
  statement {
    sid    = "AllowListAndDecryptDataStore"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      module.s3-data-bucket.bucket.arn,
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
      "${module.s3-data-bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "this_transfer_workflow" {
  count  = local.is-production || local.is-development ? 1 : 0
  role   = aws_iam_role.s3_database_backups_role[0].name
  policy = data.aws_iam_policy_document.rds_data_store_access[0].json
}
