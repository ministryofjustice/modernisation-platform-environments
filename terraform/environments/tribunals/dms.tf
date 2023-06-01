// These resources setup and configure AWS DMS (Database Migration Service) to migrate data from the existing RDS instance in the Tactical Products AWS account to the new RDS instance in the Modernisation Platform.
// Split into 3 sections: Shared resources (resources that are the same in both Pre-Prod and Prod environments), and then Pre-Prod and Prod specific resources, as each will have different target endpoints.
// DMS is not used in the Dev environment.

//Shared resources:
resource "aws_dms_endpoint" "target" {
  depends_on    = [aws_db_instance.rdsdb]
  database_name = local.application_data.accounts[local.environment].db_name
  endpoint_id   = "tribunals-target"
  endpoint_type = "target"
  engine_name   = "sqlserver"
  username      = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  password      = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  port          = 1433
  server_name   = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["host"]
  ssl_mode      = "none"
}

resource "aws_dms_replication_instance" "tribunals_replication_instance" {
  allocated_storage           = 300
  apply_immediately           = true
  availability_zone           = "eu-west-2a"
  engine_version              = "3.4.7"
  multi_az                    = false
  publicly_accessible         = true
  auto_minor_version_upgrade  = true
  replication_instance_class  = "dms.t3.large"
  replication_instance_id     = "tribunals-replication-instance"
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
    from_port   = 1433
    to_port     = 1433
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

