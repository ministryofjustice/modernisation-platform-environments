resource "aws_db_instance" "tipstaff_db" {
  allocated_storage      = local.application_data.accounts[local.environment].allocated_storage
  db_name                = local.application_data.accounts[local.environment].db_name
  storage_type           = local.application_data.accounts[local.environment].storage_type
  engine                 = local.application_data.accounts[local.environment].engine
  identifier             = local.application_data.accounts[local.environment].identifier
  engine_version         = local.application_data.accounts[local.environment].engine_version
  instance_class         = local.application_data.accounts[local.environment].instance_class
  username               = random_string.username.result
  password               = random_password.password.result
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.postgresql_db_sc.id]
  db_subnet_group_name   = aws_db_subnet_group.dbsubnetgroup.name
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = data.aws_subnets.shared-public.ids
}

resource "aws_security_group" "postgresql_db_sc" {
  name        = "postgres_security_group"
  description = "control access to the database"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "MOJ Digital VPN access"
    cidr_blocks = [local.application_data.accounts[local.environment].moj_ip]
  }
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    description     = "Allows ECS service to access RDS"
    security_groups = [aws_security_group.ecs_service.id]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allows Github Actions to access RDS"
    cidr_blocks = ["${jsondecode(data.http.myip.response_body)["ip"]}/32"]
  }
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    description     = "Allows DMS to access RDS"
    security_groups = [aws_security_group.vpc_dms_replication_instance_group.id]
  }
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

resource "null_resource" "setup_db" {
  depends_on = [aws_db_instance.tipstaff_db]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "chmod +x ./setup-postgresql.sh; ./setup-postgresql.sh"

    environment = {
      DB_HOSTNAME              = aws_db_instance.tipstaff_db.address
      DB_NAME                  = aws_db_instance.tipstaff_db.db_name
      TIPSTAFF_DB_USERNAME_DEV = random_string.username.result
      TIPSTAFF_DB_PASSWORD_DEV = random_password.password.result
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}
