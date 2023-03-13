# This contains the resources required to build the oas rds instance plus associated resources.

#TODO 1) Get ARN for the Shared Key and apply for snapshots & PI.
#TODO 2) Snapshot ARN in the vars

# RDS Subnet Group


resource "aws_db_subnet_group" "appdbsubnetgroup" {
  name       = "appdbsubnetgroup"
  subnet_ids = [var.vpc_subnet_a_id, var.vpc_subnet_b_id, var.vpc_subnet_c_id]

  tags = {
    Name = "${var.application_name}-${var.environment}-subnetgroup",
    Keep = "true"
  }
}


# RDS Parameter group

resource "aws_db_parameter_group" "appdbparametergroup19" {
  name        = "appdbparametergroup19"
  family      = "oracle-se2-19"
  description = "${var.application_name}-${var.environment}-parametergroup"

  parameter {
    name  = "remote_dependencies_mode"
    value = "SIGNATURE"
  }

  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "10"
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-parametergroup"
  }

}



# RDS Option group

#TODO - These settings are for OAS only so we need to consider whether they should be in the module or not.

resource "aws_db_option_group" "appdboptiongroup19" {
  name                     = "appdboptiongroup19"
  option_group_description = "${var.application_name}-${var.environment}-optiongroup"
  engine_name              = var.engine
  major_engine_version     = "19"

  option {
    option_name = "STATSPACK"
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-optiongroup",
    Keep = "true"
  }

}


# Random Secret for the DB Password to be used for installation of OAS only
# TODO Is this still required when AMI is being copied over instead? If so need to make sure that Terraform deployment either will not update the password in Secret Manager, of that wherever the password is being used gets updated to utilise the new password

resource "random_password" "rds_password" {
  length  = 16
  special = false
}


resource "aws_secretsmanager_secret" "rds_password_secret" {
  name = "${var.application_name}/app/db-master-password"
  description = "This secret has a dynamically generated password."
  tags = merge(
    var.tags,
    { "Name" = "${var.application_name}/app/db-master-password" },
  )
}


resource "aws_secretsmanager_secret_version" "rds_password_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_password_secret.id
  secret_string = jsonencode(
    {
      username = var.username
      password = random_password.rds_password.result
    }
  )
}

# RDS database

resource "aws_db_instance" "appdb1" {
  allocated_storage           = var.allocated_storage
  db_name                     = upper(var.application_name)
  identifier                  = var.identifier_name
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  storage_type                = var.storage_type
  backup_retention_period     = var.backup_retention_period
  backup_window               = var.backup_window
  maintenance_window          = var.maintenance_window
  character_set_name          = var.character_set_name
  availability_zone           = var.availability_zone
  multi_az                    = var.multi_az
  username                    = var.username
  password                    = random_password.rds_password.result
  vpc_security_group_ids      = [aws_security_group.laalz-secgroup.id, aws_security_group.vpc-secgroup.id]
  skip_final_snapshot         = false
  final_snapshot_identifier   = "${var.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name        = aws_db_parameter_group.appdbparametergroup19.name
  option_group_name           = aws_db_option_group.appdboptiongroup19.name
  db_subnet_group_name        = aws_db_subnet_group.appdbsubnetgroup.name
  license_model               = var.license_model
  deletion_protection         = var.deletion_protection
  copy_tags_to_snapshot       = true
  storage_encrypted           = true
  apply_immediately           = true
  snapshot_identifier         = var.rds_snapshot_arn
  kms_key_id                  = var.rds_kms_key_arn
  tags = {
    Name = "${var.application_name}-${var.environment}-database"
  }

  timeouts {
    create = "60m"
    delete = "2h"
  }

}

# enabled_cloudwatch_logs_exports       = ["general", "error", "slowquery"]

# Security Group

resource "aws_security_group" "laalz-secgroup" {
  name        = "laalz-secgroup"
  description = "RDS access with the LAA Landing Zone"
  vpc_id      = var.vpc_shared_id

  ingress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.lz_vpc_cidr]
  }

  egress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.lz_vpc_cidr]
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-laalz-secgroup"
  }
}

resource "aws_security_group" "vpc-secgroup" {
  name        = "vpc-secgroup"
  description = "RDS Access with the shared vpc"
  vpc_id      = var.vpc_shared_id

  ingress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.vpc_shared_cidr]
  }

  egress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.vpc_shared_cidr]
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-vpc-secgroup"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.appdb1.address
}
