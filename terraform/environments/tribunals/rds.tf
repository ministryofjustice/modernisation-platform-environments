# trivy:ignore:AVD-AWS-0080
resource "aws_db_instance" "rdsdb" {
  #checkov:skip=CKV_AWS_16: "Ensure all data stored in the RDS is securely encrypted at rest"
  #checkov:skip=CKV_AWS_118: "Ensure that enhanced monitoring is enabled for Amazon RDS instances" - false error
  #checkov:skip=CKV_AWS_157: "Ensure that RDS instances have Multi-AZ enabled"
  #checkov:skip=CKV_AWS_293: "Ensure that AWS database instances have deletion protection enabled"
  #checkov:skip=CKV_AWS_353: "Ensure that RDS instances have performance insights enabled"
  #checkov:skip=CKV_AWS_354: "Ensure RDS Performance Insights are encrypted using KMS CMKs"
  #checkov:skip=CKV_AWS_129: "RDS logging not required for this database instance"
  #checkov:skip=CKV2_AWS_60: "Copy tags to snapshots not required as final snapshots are disabled"
  allocated_storage = local.application_data.accounts[local.environment].allocated_storage
  //db_name                 = DBName must be null for engine: sqlserver-se
  storage_type   = local.application_data.accounts[local.environment].storage_type
  identifier     = local.application_data.accounts[local.environment].db_identifier
  engine         = local.application_data.accounts[local.environment].engine
  engine_version = local.application_data.accounts[local.environment].engine_version
  instance_class = local.application_data.accounts[local.environment].instance_class
  username       = local.application_data.accounts[local.environment].username
  password       = random_password.password.result
  port           = 1433

  auto_minor_version_upgrade = true
  skip_final_snapshot        = true

  license_model       = "license-included"
  publicly_accessible = false

  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sqlserver_db_sc.id]

  tags = {
    Name = "tribunals"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "dbsubnetgroup"
  subnet_ids = data.aws_subnets.shared-private.ids
}

resource "aws_security_group" "sqlserver_db_sc" {
  #checkov:skip=CKV_AWS_382:"RDS required unrestricted egress"
  name        = "sqlserver_security_group"
  description = "control access to the database"
  vpc_id      = data.aws_vpc.shared.id
  ingress {
    protocol    = "tcp"
    description = "Allow PSQL traffic from bastion"
    from_port   = 1433
    to_port     = 1433
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }
  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    description     = "Allows ECS cluster to access RDS"
    security_groups = [aws_security_group.cluster_ec2.id]
  }
  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    description     = "Allows each Tribunal ECS service to access RDS"
    security_groups = [aws_security_group.ecs_service.id]
  }
  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
