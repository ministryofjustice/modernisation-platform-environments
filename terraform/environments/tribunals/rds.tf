resource "aws_db_instance" "rdsdb" {
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

  skip_final_snapshot = true

  license_model       = "license-included"
  publicly_accessible = true

  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.dbsubnetgroup.name
  vpc_security_group_ids = [aws_security_group.sqlserver_db_sc.id]

  tags = {
    Name = "tribunals"
  }
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = data.aws_subnets.shared-public.ids
}

resource "aws_security_group" "sqlserver_db_sc" {
  name        = "sqlserver_security_group"
  description = "control access to the database"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    description = "MOJ Digital VPN access"
    cidr_blocks = [local.application_data.accounts[local.environment].moj_ip]
  }
  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    description = "Allows Github Actions to access RDS"
    cidr_blocks = ["${jsondecode(data.http.myip.response_body)["ip"]}/32"]
  }
  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    description     = "Allows DMS to access RDS"
    security_groups = [aws_security_group.vpc_dms_replication_instance_group.id]
  }
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
  # ingress {
  #   from_port       = 1433
  #   to_port         = 1433
  #   protocol        = "tcp"
  #   description     = "Allows Care Standards ECS service to access RDS"
  #   security_groups = [module.cares-ecs.cluster_ec2_security_group_id]
  # }
  # ingress {
  #   from_port       = 1433
  #   to_port         = 1433
  #   protocol        = "tcp"
  #   description     = "Allows Lands Chamber ECS service to access RDS"
  #   security_groups = [module.lands-ecs.cluster_ec2_security_group_id]
  # }
  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    description     = "Allows Administrative Appeals ECS service to access RDS"
    security_groups = [module.appeals.cluster_ec2_security_group_id]
  }
  # ingress {
  #   from_port       = 1433
  #   to_port         = 1433
  #   protocol        = "tcp"
  #   description     = "Allows Transport ECS service to access RDS"
  #   security_groups = [module.transport-ecs.cluster_ec2_security_group_id]
  # }
  # ingress {
  #   from_port       = 1433
  #   to_port         = 1433
  #   protocol        = "tcp"
  #   description     = "Allows Land Registration Division ECS service to access RDS"
  #   security_groups = [module.hmlands-ecs.cluster_ec2_security_group_id]
  # }
  # ingress {
  #   from_port       = 1433
  #   to_port         = 1433
  #   protocol        = "tcp"
  #   description     = "Allows Criminal Injuries ECS service to access RDS"
  #   security_groups = [module.cicap-ecs.cluster_ec2_security_group_id]
  # }
  # ingress {
  #   from_port       = 1433
  #   to_port         = 1433
  #   protocol        = "tcp"
  #   description     = "Allows Employment Appeals ECS service to access RDS"
  #   security_groups = [module.eat-ecs.cluster_ec2_security_group_id]
  # }
  # ingress {
  #   from_port       = 1433
  #   to_port         = 1433
  #   protocol        = "tcp"
  #   description     = "Allows Finance and Tax ECS service to access RDS"
  #   security_groups = [module.ftt-ecs.cluster_ec2_security_group_id]
  # }
  # ingress {
  #   from_port       = 1433
  #   to_port         = 1433
  #   protocol        = "tcp"
  #   description     = "Allows Immigration Services ECS service to access RDS"
  #   security_groups = [module.imset-ecs.cluster_ec2_security_group_id]
  # }
  # ingress {
  #   from_port       = 1433
  #   to_port         = 1433
  #   protocol        = "tcp"
  #   description     = "Allows Information Tribunal ECS service to access RDS"
  #   security_groups = [module.it-ecs.cluster_ec2_security_group_id]
  # }
  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "http" "myip" {
  url = "http://ipinfo.io/json"
}