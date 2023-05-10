resource "aws_dms_endpoint" "source" {
  depends_on                  = [null_resource.setup_target_rds_security_group, aws_db_instance.tipstaff_db, aws_dms_endpoint.target, aws_dms_replication_instance.tipstaff_replication_instance]
  database_name               = "tipstaff_staging"
  endpoint_id                 = "tipstaff-source"
  endpoint_type               = "source"
  engine_name                 = "postgres"
  username                    = jsondecode(aws_secretsmanager_secret_version.tactical_products_rds_credentials.secret_string)["DTS-STAGING-DB-MASTER-USER"]
  password                    = jsondecode(aws_secretsmanager_secret_version.tactical_products_rds_credentials.secret_string)["DTS-STAGING-DB-MASTER-PASSWORD"]
  port                        = 5432
  server_name                 = jsondecode(aws_secretsmanager_secret_version.tactical_products_rds_credentials.secret_string)["DTS-STAGING-DB-HOSTNAME"]
  ssl_mode                    = "none"
  extra_connection_attributes = "heartbeatEnable=Y;"
}

resource "aws_dms_endpoint" "target" {
  depends_on = [aws_db_instance.tipstaff_db]

  database_name = local.application_data.accounts[local.environment].db_name
  endpoint_id   = "tipstaff-target"
  endpoint_type = "target"
  engine_name   = "postgres"
  username      = random_string.username.result
  password      = random_password.password.result
  port          = 5432
  server_name   = aws_db_instance.tipstaff_db.address
  ssl_mode      = "none"
}

resource "aws_dms_replication_instance" "tipstaff_replication_instance" {
  allocated_storage           = 300
  apply_immediately           = true
  availability_zone           = "eu-west-2a"
  engine_version              = "3.4.7"
  multi_az                    = false
  publicly_accessible         = true
  auto_minor_version_upgrade  = true
  replication_instance_class  = "dms.t3.large"
  replication_instance_id     = "tipstaff-replication-instance"
  vpc_security_group_ids      = [aws_security_group.vpc_dms_replication_instance_group.id]
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_replication_subnet_group.id
}

resource "aws_dms_replication_subnet_group" "dms_replication_subnet_group" {
  replication_subnet_group_id          = "dms-replication-subnet-group"
  subnet_ids                           = data.aws_subnets.shared-public.ids
  replication_subnet_group_description = "DMS replication subnet group"
}

resource "aws_security_group" "vpc_dms_replication_instance_group" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "vpc-dms-replication-instance-group"
  description = "allow dms replication instance access to the shared vpc on the modernisation platform"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allow all inbound traffic"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all outbound traffic"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create DMS VPC Role
resource "aws_iam_role" "dms_vpc_role" {
  name = "dms-vpc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "dms_vpc_management_policy" {
  name = "dms-vpc-management-policy"
  role = aws_iam_role.dms_vpc_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "rds:*",
          "dms:*",
          "ec2:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_dms_replication_task" "tipstaff_migration_task" {
  depends_on               = [null_resource.setup_target_rds_security_group, aws_db_instance.tipstaff_db, aws_dms_endpoint.target, aws_dms_endpoint.source, aws_dms_replication_instance.tipstaff_replication_instance]
  migration_type           = "full-load"
  replication_instance_arn = aws_dms_replication_instance.tipstaff_replication_instance.replication_instance_arn
  replication_task_id      = "tipstaff-migration-task"
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  start_replication_task   = false

  replication_task_settings = jsonencode({
    TargetMetadata = {
      FullLobMode  = true,
      LobChunkSize = 64
    },
    FullLoadSettings = {
      TargetTablePrepMode = "DO_NOTHING"
    },
    ControlTablesSettings = {
      historyTimeslotInMinutes = 5
    },
    ErrorBehavior = {
      DataErrorPolicy            = "LOG_ERROR"
      ApplyErrorDeletePolicy     = "LOG_ERROR"
      ApplyErrorInsertPolicy     = "LOG_ERROR"
      ApplyErrorUpdatePolicy     = "LOG_ERROR"
      ApplyErrorEscalationCount  = 0
      ApplyErrorEscalationPolicy = "LOG_ERROR"
    }
  })

  table_mappings = jsonencode({
    rules = [
      {
        "rule-type" = "selection"
        "rule-id"   = "1"
        "rule-name" = "1"
        "object-locator" = {
          "schema-name" = "dbo"
          "table-name"  = "%"
        }
        "rule-action" = "include"
      }
    ]
  })

}

resource "aws_security_group" "modernisation_dms_access" {
  provider    = aws.tacticalproducts
  name        = "modernisation_dms_access"
  description = "allow dms access to the database for the modernisation platform"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allow DMS to connect to source database"
    cidr_blocks = ["${aws_dms_replication_instance.tipstaff_replication_instance.replication_instance_public_ips[0]}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "setup_target_rds_security_group" {
  depends_on = [aws_dms_replication_instance.tipstaff_replication_instance]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "chmod +x ./setup-security-group.sh; ./setup-security-group.sh"

    environment = {
      DMS_SECURITY_GROUP            = aws_security_group.modernisation_dms_access.id
      DMS_TARGET_ACCOUNT_ACCESS_KEY = jsondecode(aws_secretsmanager_secret_version.tactical_products_rds_credentials.secret_string)["ACCESS_KEY"]
      DMS_TARGET_ACCOUNT_SECRET_KEY = jsondecode(aws_secretsmanager_secret_version.tactical_products_rds_credentials.secret_string)["SECRET_KEY"]
      DMS_TARGET_ACCOUNT_REGION     = "eu-west-2"
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}
