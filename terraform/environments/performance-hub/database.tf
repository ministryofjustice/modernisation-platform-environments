#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------

resource "aws_db_instance" "database" {
  #tfsec:ignore:AWS099
  #checkov:skip=CKV_AWS_118
  #checkov:skip=CKV_AWS_157
  count                               = local.app_data.accounts[local.environment].db_enabled ? 1 : 0
  identifier                          = local.application_name
  allocated_storage                   = local.app_data.accounts[local.environment].db_allocated_storage
  storage_type                        = "gp2"
  engine                              = "sqlserver-se"
  engine_version                      = "15.00.4073.23.v1"
  license_model                       = "license-included"
  instance_class                      = local.app_data.accounts[local.environment].db_instance_class
  multi_az                            = false
  username                            = local.app_data.accounts[local.environment].db_user
  password                            = aws_secretsmanager_secret_version.db_password.arn
  storage_encrypted                   = true
  iam_database_authentication_enabled = false
  vpc_security_group_ids              = [aws_security_group.db.id]
  #snapshot_identifier                 = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id, local.app_data.accounts[local.environment].db_snapshot_identifier)
  backup_retention_period         = 30
  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  final_snapshot_identifier       = "final-snapshot"
  kms_key_id                      = aws_kms_key.rds.arn
  deletion_protection             = false
  option_group_name               = aws_db_option_group.db_option_group.name
  db_subnet_group_name            = aws_db_subnet_group.db.id
  enabled_cloudwatch_logs_exports = ["error"]
  ca_cert_identifier              = "rds-ca-rsa2048-g1"
  # BE VERY CAREFUL with apply_immediately = true. Useful if you want to see the results, but can cause a reboot
  # of RDS meaning the connected app will fail.
  # When apply_immediately=false, RDS changes are applied during the next maintenance_window
  apply_immediately = false

  # timeouts {
  #   create = "40m"
  #   delete = "40m"
  #   update = "80m"
  # }

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name                = "${local.application_name}-database",
      instance-scheduling = "skip-scheduling"
    }
  )
}

resource "aws_db_option_group" "db_option_group" {
  name                     = "${local.application_name}-option-group"
  option_group_description = "Terraform Option Group"
  engine_name              = "sqlserver-se"
  major_engine_version     = "15.00"

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.s3_database_backups_role.arn
    }
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "${local.application_name}-db-subnet-group"
  subnet_ids = sort(data.aws_subnets.shared-data.ids)
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-subnet-group"
    }
  )
}

resource "aws_security_group" "db" {
  name        = "${local.application_name}-db-sg"
  description = "Allow DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-sg"
    }
  )
}

resource "aws_security_group_rule" "db_mgmt_ingress_rule" {
  type                     = "ingress"
  description              = "Default SQL Server port 1433"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

resource "aws_security_group_rule" "db_ecs_ingress_rule" {
  type                     = "ingress"
  description              = "Default SQL Server port 1433"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = module.windows-new-ecs.cluster_ec2_security_group_id
}

resource "aws_security_group_rule" "db_bastion_ingress_rule" {
  type                     = "ingress"
  description              = "Default SQL Server port 1433"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "db_windows_server_failover_tcp_ingress_rule" {
  type                     = "ingress"
  description              = "Windows Server Failover Cluster port TCP Ingress"
  from_port                = 3343
  to_port                  = 3343
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

resource "aws_security_group_rule" "db_windows_server_failover_tcp_egress_rule" {
  type                     = "egress"
  description              = "Windows Server Failover Cluster port TCP Egress"
  from_port                = 3343
  to_port                  = 3343
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

resource "aws_security_group_rule" "db_windows_server_failover_udp_ingress_rule" {
  type                     = "ingress"
  description              = "Windows Server Failover Cluster port UDP Ingress"
  from_port                = 3343
  to_port                  = 3343
  protocol                 = "udp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

resource "aws_security_group_rule" "db_windows_server_failover_udp_egress_rule" {
  type                     = "egress"
  description              = "Windows Server Failover Cluster port UDP Egress"
  from_port                = 3343
  to_port                  = 3343
  protocol                 = "udp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

#------------------------------------------------------------------------------
# S3 Bucket for Database backup files
#------------------------------------------------------------------------------
#tfsec:ignore:AWS002 tfsec:ignore:AWS098
resource "aws_s3_bucket" "database_backup_files" {
  #checkov:skip=CKV_AWS_18
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV2_AWS_6
  bucket = "${local.application_name}-db-backups-${local.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-backups-s3"
    }
  )
}

resource "aws_s3_bucket_acl" "database_backup_files" {
  bucket = aws_s3_bucket.database_backup_files.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "database_backup_files" {
  bucket = aws_s3_bucket.database_backup_files.id
  rule {
    id     = "tf-s3-lifecycle"
    status = "Enabled"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "database_backup_files" {
  bucket = aws_s3_bucket.database_backup_files.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "database_backup_files" {
  bucket = aws_s3_bucket.database_backup_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

#S3 bucket access policy
resource "aws_iam_policy" "s3_database_backups_policy" {
  name   = "${local.application_name}-s3-database_backups-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:DescribeKey",
        "kms:GenerateDataKey",
        "kms:Encrypt",
        "kms:Decrypt"
      ],
      "Resource": "${aws_kms_key.s3.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
          "${aws_s3_bucket.database_backup_files.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectMetaData",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
      "Resource": [
        "${aws_s3_bucket.database_backup_files.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "s3_database_backups_role" {
  name               = "${local.application_name}-s3-database-backups-role"
  assume_role_policy = data.aws_iam_policy_document.s3-access-policy.json
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-s3-db-backups-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "s3_database_backups_attachment" {
  role       = aws_iam_role.s3_database_backups_role.name
  policy_arn = aws_iam_policy.s3_database_backups_policy.arn
}

#------------------------------------------------------------------------------
# KMS setup for RDS
#------------------------------------------------------------------------------

resource "aws_kms_key" "rds" {
  description         = "Encryption key for rds"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.rds-kms.json

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-rds-kms"
    }
  )
}

resource "aws_kms_alias" "rds-kms-alias" {
  name          = "alias/rds"
  target_key_id = aws_kms_key.rds.arn
}

data "aws_iam_policy_document" "rds-kms" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_109
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}
