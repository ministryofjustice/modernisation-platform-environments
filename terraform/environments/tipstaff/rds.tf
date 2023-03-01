resource "aws_db_instance" "tipstaffdbdev" {
  allocated_storage      = local.application_data.accounts[local.environment].allocated_storage
  db_name                = local.application_data.accounts[local.environment].db_name
  storage_type           = local.application_data.accounts[local.environment].storage_type
  identifier             = local.application_data.accounts[local.environment].identifier
  engine                 = local.application_data.accounts[local.environment].engine
  engine_version         = local.application_data.accounts[local.environment].engine_version
  instance_class         = local.application_data.accounts[local.environment].instance_class
  username               = jsondecode(data.aws_secretsmanager_secret_version.db_username.secret_string)["LOCAL_DB_USERNAME"]
  password               = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["LOCAL_DB_PASSWORD"]
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.postgresql_db_sc.id]
  db_subnet_group_name   = aws_db_subnet_group.dbsubnetgroup.name
  publicly_accessible    = true
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
}

resource "aws_security_group" "postgresql_db_sc" {
  name        = "postgres_security_group"
  description = "control access to the database"
  vpc_id      = data.aws_vpc.shared.id
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    description = "MOJ Digital VPN access"
    cidr_blocks = [local.application_data.accounts[local.environment].moj_ip]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allows codebuild access to RDS"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
