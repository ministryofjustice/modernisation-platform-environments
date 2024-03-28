#-----------------------------------------------------------------------------
# Database
#-----------------------------------------------------------------------------

resource "aws_db_instance" "database" {
  allocated_storage         = local.application_data.accounts[local.environment].db_allocated_storage
  storage_type              = "gp2"
  engine                    = "sqlserver-web"
  engine_version            = "14.00.3381.3.v1"
  instance_class            = local.application_data.accounts[local.environment].db_instance_class
  identifier                = local.application_data.accounts[local.environment].db_instance_identifier
  username                  = local.application_data.accounts[local.environment].db_user
  password                  = aws_secretsmanager_secret_version.db_password.secret_string
  vpc_security_group_ids    = [aws_security_group.db.id]
  depends_on                = [aws_security_group.db]
  snapshot_identifier       = local.application_data.accounts[local.environment].db_snapshot_identifier
  db_subnet_group_name      = aws_db_subnet_group.db.id
  final_snapshot_identifier = "final-snapshot-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  publicly_accessible       = false
}

resource "aws_db_instance_role_association" "database" {
  db_instance_identifier = aws_db_instance.database.identifier
  feature_name           = "S3_INTEGRATION"
  role_arn               = aws_iam_role.S3_db_backup_restore_access.arn
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
  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#--------------------------
# KMS setup for RDS
#--------------------------

resource "aws_kms_key" "rds" {
  description         = "Encryption key for rds"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.rds-kms.json
}

resource "aws_kms_alias" "rds-kms-alias" {
  name          = "alias/rds"
  target_key_id = aws_kms_key.rds.arn
}

data "aws_iam_policy_document" "rds-kms" {
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
