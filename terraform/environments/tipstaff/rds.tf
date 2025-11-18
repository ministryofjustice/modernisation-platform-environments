resource "aws_db_instance" "tipstaff_db" {
  count                       = local.is-development ? 0 : 1
  allocated_storage           = local.application_data.accounts[local.environment].allocated_storage
  db_name                     = local.application_data.accounts[local.environment].db_name
  storage_type                = local.application_data.accounts[local.environment].storage_type
  engine                      = local.application_data.accounts[local.environment].engine
  identifier                  = local.application_data.accounts[local.environment].identifier
  engine_version              = local.application_data.accounts[local.environment].engine_version
  instance_class              = local.application_data.accounts[local.environment].instance_class
  username                    = local.application_data.accounts[local.environment].db_username
  password                    = random_password.password.result
  skip_final_snapshot         = true
  publicly_accessible         = false
  vpc_security_group_ids      = [aws_security_group.postgresql_db_sc[0].id]
  db_subnet_group_name        = aws_db_subnet_group.dbsubnetgroup.name
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  ca_cert_identifier          = "rds-ca-rsa2048-g1"
  apply_immediately           = true
  maintenance_window          = local.is-production ? null : "tue:20:20-tue:20:50"
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = data.aws_subnets.shared-public.ids
}

resource "aws_security_group" "postgresql_db_sc" {
  count       = local.is-development ? 0 : 1
  name        = "postgres_security_group"
  description = "control access to the database"
  vpc_id      = data.aws_vpc.shared.id
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
    protocol    = "tcp"
    description = "Allow PSQL traffic from bastion"
    from_port   = 5432
    to_port     = 5432
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }
  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// DB setup for the development environment (set to publicly accessible to allow GitHub Actions access):
resource "aws_db_instance" "tipstaff_db_dev" {
  count                       = local.is-development ? 1 : 0
  allocated_storage           = local.application_data.accounts[local.environment].allocated_storage
  db_name                     = local.application_data.accounts[local.environment].db_name
  storage_type                = local.application_data.accounts[local.environment].storage_type
  engine                      = local.application_data.accounts[local.environment].engine
  identifier                  = local.application_data.accounts[local.environment].identifier
  engine_version              = local.application_data.accounts[local.environment].engine_version
  instance_class              = local.application_data.accounts[local.environment].instance_class
  username                    = local.application_data.accounts[local.environment].db_username
  password                    = random_password.password.result
  skip_final_snapshot         = true
  publicly_accessible         = true
  vpc_security_group_ids      = [aws_security_group.postgresql_db_sc_dev[0].id]
  db_subnet_group_name        = aws_db_subnet_group.dbsubnetgroup.name
  allow_major_version_upgrade = true
}

resource "aws_security_group" "postgresql_db_sc_dev" {
  count       = local.is-development ? 1 : 0
  name        = "postgres_security_group_dev"
  description = "control access to the database"
  vpc_id      = data.aws_vpc.shared.id
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
    protocol    = "tcp"
    description = "Allow PSQL traffic from bastion"
    from_port   = 5432
    to_port     = 5432
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
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
  count = local.is-development ? 1 : 0

  depends_on = [aws_db_instance.tipstaff_db_dev[0]]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "chmod +x ./setup-dev-db.sh; ./setup-dev-db.sh"

    environment = {
      DB_HOSTNAME          = aws_db_instance.tipstaff_db_dev[0].address
      DB_NAME              = aws_db_instance.tipstaff_db_dev[0].db_name
      TIPSTAFF_DB_USERNAME = aws_db_instance.tipstaff_db_dev[0].username
      TIPSTAFF_DB_PASSWORD = random_password.password.result
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}
