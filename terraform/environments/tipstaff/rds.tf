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
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.postgresql_db_sc.id]
  db_subnet_group_name   = aws_db_subnet_group.dbsubnetgroup.name
}

//Not needed??
resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = data.aws_subnets.shared-public.ids
}

//Not needed??
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
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "null_resource" "setup_db" {
  depends_on = [aws_db_instance.tipstaffdbdev]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "chmod +x ./setup-postgresql.sh; ./setup-postgresql.sh"

    environment = {
      DB_HOSTNAME = aws_db_instance.tipstaffdbdev.address
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}
