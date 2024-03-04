#------------------------------------------------------------------------------
resource "aws_db_instance" "database" {
#   count = local.is-production ? 1 : 0

  identifier    = "terraform-db-instance-test"
  username      = "admin"
  password      = "Test-123"
  license_model = "license-included"

  engine         = "sqlserver-se"
  engine_version = "13.00.6435.1.v1"
  instance_class = "db.m5.large"

  storage_type          = "gp2"
  allocated_storage     = 50
  max_allocated_storage = 1000
  storage_encrypted     = true

  multi_az          = false
  availability_zone = "eu-west-2b"

  db_subnet_group_name   = aws_db_subnet_group.db.id
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = true
  port                   = 1433

  auto_minor_version_upgrade = true
  skip_final_snapshot        = true
  maintenance_window         = "Mon:00:00-Mon:03:00"
  deletion_protection        = false

#   option_group_name                   = aws_db_option_group.db_option_group.name

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
  subnet_ids = sort(data.aws_subnets.shared-public.ids)
  
  tags = local.tags
}

#------------------------------------------------------------------------------

# resource "aws_db_option_group" "db_option_group" {
#   name                     = "option-group"
#   option_group_description = "Terraform Option Group"
#   engine_name              = "sqlserver-se"
#   major_engine_version     = "15.00"

#   option {
#     option_name = "SQLSERVER_BACKUP_RESTORE"

#     option_settings {
#       name  = "IAM_ROLE_ARN"
#       value = aws_iam_role.s3_database_backups_role.arn
#     }
#   }
# }

# #------------------------------------------------------------------------------

# data "aws_iam_policy_document" "s3-access-policy" {
#   version = "2012-10-17"
#   statement {
#     sid    = ""
#     effect = "Allow"
#     actions = [
#       "sts:AssumeRole",
#     ]
#     principals {
#       type = "Service"
#       identifiers = [
#         "rds.amazonaws.com",
#       ]
#     }
#   }
# }

# resource "aws_iam_role" "s3_database_backups_role" {
#   name               = "${local.application_name}-s3-database-backups-role"
#   assume_role_policy = data.aws_iam_policy_document.s3-access-policy.json
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-s3-db-backups-role"
#     }
#   )
# }

# data "aws_iam_policy_document" "data_store" {
#   statement {
#     sid = "EnforceTLSv12orHigher"
#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }
#     effect  = "Deny"
#     actions = ["s3:*"]
#     resources = [
#       aws_s3_bucket.data_store.arn,
#       "${aws_s3_bucket.data_store.arn}/*"
#     ]
#     condition {
#       test     = "NumericLessThan"
#       variable = "s3:TlsVersion"
#       values   = [1.2]
#     }
#   }
# }

# resource "aws_iam_role_policy_attachment" "s3_database_backups_attachment" {
#   role       = aws_iam_role.s3_database_backups_role.name
#   policy_arn = aws_iam_policy.s3_database_backups_policy.arn
# }




#------------------------------------------------------------------------------





