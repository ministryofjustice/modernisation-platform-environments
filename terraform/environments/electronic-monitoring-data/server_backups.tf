data "aws_secretsmanager_secret" "server_backups" {
  name = "server_backups"
}

data "aws_secretsmanager_secret_version" "server_backups" {
  secret_id = data.aws_secretsmanager_secret.server_backups.id
}

#------------------------------------------------------------------------------
resource "aws_db_instance" "database" {
#   count = local.is-production ? 1 : 0

  identifier                          = "terraform-db-instance-test"

  engine                              = "sqlserver-se"
  engine_version                      = "13.00.6435.1.v1"
  instance_class                      = "db.m5.large"

  storage_type                        = "gp2"
  allocated_storage                   = 100
  max_allocated_storage               = 5000
  storage_encrypted                   = true

  multi_az                            = false

  db_subnet_group_name    = aws_db_subnet_group.db.id
  vpc_security_group_ids  = [aws_security_group.db.id]
  publicly_accessible     = true
  port                    = 1433

  license_model = "license-included"
  username = jsondecode(data.aws_secretsmanager_secret_version.server_backups.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.server_backups.secret_string)["password"]


  auto_minor_version_upgrade = true
  skip_final_snapshot = true
  maintenance_window                  = "Mon:00:00-Mon:03:00"
  deletion_protection                 = false

  option_group_name                   = aws_db_option_group.sqlserver_backup_restore.name

  iam_database_authentication_enabled = false

#   kms_key_id                          = aws_kms_key.rds.arn
#   enabled_cloudwatch_logs_exports     = ["error"]

  tags = local.tags
}

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

#------------------------------------------------------------------------------

resource "aws_db_subnet_group" "db" {
  name       = "db-subnet-group"
  subnet_ids = data.aws_subnets.shared-public.ids
  
  tags = local.tags
}

#------------------------------------------------------------------------------

resource "aws_db_option_group" "sqlserver_backup_restore" {
  name                     = "option-group"
  option_group_description = "Terraform Option Group"
  engine_name              = "sqlserver-se"
  major_engine_version     = "13.00"

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.s3_database_backups_role.arn
    }
  }
}

# #------------------------------------------------------------------------------

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
    sid    = "AllowReadDataStore"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.data_store.arn}/*"]
  }
}

resource "aws_iam_role_policy" "this_transfer_workflow" {
  role   = aws_iam_role.s3_database_backups_role.name
  policy = data.aws_iam_policy_document.rds_data_store_access.json
}

#------------------------------------------------------------------------------





