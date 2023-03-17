resource "aws_db_instance" "rdsdb" {
  allocated_storage = local.application_data.accounts[local.environment].allocated_storage
  //db_name                 = DBName must be null for engine: sqlserver-se
  storage_type   = local.application_data.accounts[local.environment].storage_type
  identifier     = local.application_data.accounts[local.environment].identifier
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
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    description = "MOJ Digital VPN access"
    cidr_blocks = [local.application_data.accounts[local.environment].moj_ip]
  }
  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    description = "Allows codebuild access to RDS"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "${local.application_data.accounts[local.environment].identifier}-credentials"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = <<EOF
{
  "username": "${aws_db_instance.rdsdb.username}",
  "password": "${aws_db_instance.rdsdb.password}",
  "engine": "${aws_db_instance.rdsdb.engine}",
  "host": "${aws_db_instance.rdsdb.address}",
  "port": ${aws_db_instance.rdsdb.port},
  "dbClusterIdentifier": "${aws_db_instance.rdsdb.ca_cert_identifier}",
  "database_name": "master"
}
EOF
}