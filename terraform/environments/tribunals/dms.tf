resource "aws_dms_replication_instance" "tribunals_replication_instance" {
  allocated_storage           = 300
  apply_immediately           = true
  availability_zone           = "eu-west-2a"
  engine_version              = "3.5.1"
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
  subnet_ids                           = data.aws_subnets.shared-private.ids
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
    description = "Allow all inbound traffic from ec2"
    security_groups = [aws_security_group.cluster_ec2.id]
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

resource "aws_dms_endpoint" "source" {
  database_name = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["dbname"]
  endpoint_id   = "tribunals-source"
  endpoint_type = "source"
  engine_name   = "sqlserver"
  password      = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  port          = 1433
  server_name   = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  ssl_mode      = "none"

  username = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
}

# Uncomment modernisation_dms_access for first time creation of the Security Group in AWS DSD Account
resource "aws_security_group" "modernisation_dms_access" {
  provider    = aws.mojdsd
  name        = "modernisation_dms_access_${local.environment}"
  description = "allow dms access to the database for the modernisation platform"

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    description = "Allow DMS to connect to source database"
    cidr_blocks = ["${aws_dms_replication_instance.tribunals_replication_instance.replication_instance_public_ips[0]}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Uncomment setup_target_rds_security_group for first time setup of DMS
// executes a local script to set up the security group for the target RDS instance in the source db aws account
resource "null_resource" "setup_target_rds_security_group" {
  depends_on = [aws_dms_replication_instance.tribunals_replication_instance]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "ifconfig -a; chmod +x ./setup-security-group.sh; ./setup-security-group.sh"

    environment = {
      DMS_SECURITY_GROUP            = aws_security_group.modernisation_dms_access.id
      EC2_INSTANCE_ID               = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["ec2-instance-id"]
      DMS_SOURCE_ACCOUNT_ACCESS_KEY = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["dms_source_account_access_key"]
      DMS_SOURCE_ACCOUNT_SECRET_KEY = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["dms_source_account_secret_key"]
      AWS_REGION                    = "eu-west-1"

    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}
