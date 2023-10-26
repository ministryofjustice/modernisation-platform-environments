resource "aws_db_instance" "wardship_db" {
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
  vpc_security_group_ids      = [aws_security_group.postgresql_db_sc.id]
  db_subnet_group_name        = aws_db_subnet_group.dbsubnetgroup.name
  allow_major_version_upgrade = true
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = data.aws_subnets.shared-public.ids
}

//SG for accessing the tacticalproducts source DB:
resource "aws_security_group" "modernisation_wardship_access" {
  provider    = aws.tacticalproducts
  name        = "modernisation_wardship_access-${local.environment}"
  description = "Allow wardship on modernisation platform to access the source database"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allow wardship on modernisation platform to connect to source database"
    cidr_blocks = ["${jsondecode(data.http.myip.response_body)["ip"]}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "postgresql_db_sc" {
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

data "http" "myip" {
  url = "http://ipinfo.io/json"
}

resource "null_resource" "setup_db" {
  count = local.is-development ? 0 : 1
  depends_on = [aws_db_instance.wardship_db]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "chmod +x ./migrate_db.sh; ./migrate_db.sh"

    environment = {
      SOURCE_DB_HOSTNAME   = jsondecode(data.aws_secretsmanager_secret_version.get_tactical_products_rds_credentials.secret_string)["SOURCE_DB_HOSTNAME"]
      SOURCE_DB_NAME       = jsondecode(data.aws_secretsmanager_secret_version.get_tactical_products_rds_credentials.secret_string)["SOURCE_DB_NAME"]
      SOURCE_DB_USERNAME   = jsondecode(data.aws_secretsmanager_secret_version.get_tactical_products_rds_credentials.secret_string)["SOURCE_DB_USERNAME"]
      SOURCE_DB_PASSWORD   = jsondecode(data.aws_secretsmanager_secret_version.get_tactical_products_rds_credentials.secret_string)["SOURCE_DB_PASSWORD"]
      DB_HOSTNAME          = aws_db_instance.wardship_db.address
      DB_NAME              = aws_db_instance.wardship_db.db_name
      WARDSHIP_DB_USERNAME = local.application_data.accounts[local.environment].db_username
      WARDSHIP_DB_PASSWORD = random_password.password.result
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

// executes a local script to set up the security group for the source RDS instance.
resource "null_resource" "setup_source_rds_security_group" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "chmod +x ./setup-security-group-${local.environment}.sh; ./setup-security-group-${local.environment}.sh"

    environment = {
      RDS_SECURITY_GROUP            = aws_security_group.modernisation_wardship_access.id
      RDS_SOURCE_ACCOUNT_ACCESS_KEY = jsondecode(data.aws_secretsmanager_secret_version.get_tactical_products_rds_credentials.secret_string)["ACCESS_KEY"]
      RDS_SOURCE_ACCOUNT_SECRET_KEY = jsondecode(data.aws_secretsmanager_secret_version.get_tactical_products_rds_credentials.secret_string)["SECRET_KEY"]
      RDS_SOURCE_ACCOUNT_REGION     = "eu-west-2"
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

// Sets up empty database for Development environment
resource "null_resource" "setup_dev_db" {
  count = local.is-development ? 1 : 0

  depends_on = [aws_db_instance.wardship_db]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "chmod +x ./setup-dev-db.sh; ./setup-dev-db.sh"

    environment = {
      DB_HOSTNAME      = aws_db_instance.wardship_db.address
      DB_NAME          = aws_db_instance.wardship_db.db_name
      WARDSHIP_DB_USERNAME = aws_db_instance.wardship_db.username
      WARDSHIP_DB_PASSWORD = random_password.password.result
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}