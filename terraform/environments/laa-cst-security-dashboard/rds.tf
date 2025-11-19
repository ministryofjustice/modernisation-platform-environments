resource "random_password" "cst_db" {
  length  = 32
  special = false
}

resource "aws_security_group" "cst_rds_sc" {
  name        = "ecs security group"
  description = "control access to the rds"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS for the Global Protect VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["35.176.93.186/32"]
  }
}

resource "aws_db_subnet_group" "cst_database" {
  name       = "${local.application_name}-tds-subnet-group"
  subnet_ids = data.aws_subnets.shared-data.ids

  tags = {
    Name = "${local.application_name}-tds-subnet-group"
  }
}

resource "aws_kms_key" "rds_performance_insights" {
  description         = "KMS key to encrypt RDS Performance Insights"
  enable_key_rotation = true

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Allow RDS Use",
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": ["kms:CreateGrant","kms:Decrypt","kms:Encrypt","kms:ReEncrypt*","kms:GenerateDataKey*","kms:DescribeKey"],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_db_instance" "cst_db" {
  identifier                    = "cst-postgres-db"
  allocated_storage             = 20
  instance_class                = "db.t3.micro"
  engine                       = "postgres"
  engine_version               = "16"
  db_subnet_group_name          = aws_db_subnet_group.cst_database.name
  username                     = "postgresadmin"
  password                     = random_password.cst_db.result
  publicly_accessible          = false
  skip_final_snapshot          = true
  deletion_protection          = true
  backup_retention_period      = 1
  vpc_security_group_ids       = [aws_security_group.cst_rds_sc.id]
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  multi_az                    = true
  monitoring_interval         = 60
  monitoring_role_arn         = aws_iam_role.rds_monitoring_role.arn
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.rds_performance_insights.arn
  iam_database_authentication_enabled = true
  storage_encrypted           = true
  copy_tags_to_snapshot       = true

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade",
    "audit"
  ]

  parameter_group_name = "default.postgres16"

  tags = {
    Name = "PostgresLatest"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.cst_db.endpoint
}

output "rds_master_username" {
  value = aws_db_instance.cst_db.username
}

output "rds_master_password" {
  value     = random_password.cst_db.result
  sensitive = true
}
