# This contains the resources required to build the maatdb rds instance plus associated resources.

#TODO 1) Get ARN for the Shared Key and apply for snapshots & PI.
#TODO 2) Snapshot ARN in the vars

# RDS Subnet Group


resource "aws_db_subnet_group" "subnet_group" {
  name       = "subnet-group"
  subnet_ids = [var.vpc_subnet_a_id, var.vpc_subnet_b_id, var.vpc_subnet_c_id]

  tags = {
    Name = "${var.application_name}-${var.environment}-subnet-group"
  }
}


# RDS Parameter group

resource "aws_db_parameter_group" "parameter_group_19" {
  name        = "parameter-group-19"
  family      = "oracle-se2-19"
  description = "${var.application_name}-${var.environment}-parameter-group"

  parameter {
    name  = "remote_dependencies_mode"
    value = "SIGNATURE"
  }

  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "10"
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-parameter-group"
  }

}



# RDS Option group

#TODO - These settings are for MAATDB only so we need to consider whether they should be in the module or not.

resource "aws_db_option_group" "option_group_19" {
  name                     = "option-group-19"
  option_group_description = "${var.application_name}-${var.environment}-option-group"
  engine_name              = var.engine
  major_engine_version     = "19"

  option {
    option_name = "STATSPACK"
  }

  option {
    option_name = "UTL_MAIL"
  }

  option {
    option_name = "Timezone"
  }

  option {
    option_name = "APEX"
    version     = "21.1.v1"
  }

  option {
    option_name = "APEX-DEV"
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-option-group"
  }

}


# Random Secret for the DB Password.

resource "random_password" "rds_password" {
  length  = 12
  special = false
}


resource "aws_secretsmanager_secret" "rds_password_secret" {
  name = "${var.application_name}-${var.environment}-rds_password_secret"
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

# From Vincent's PR
# TODO Rotation of secret which requires Lambda function created and permissions granted to Lambda to rotate. 
#
# resource "aws_secretsmanager_secret_rotation" "rds_password-rotation" {
#   secret_id           = aws_secretsmanager_secret.rds_password_secret.id
#   rotation_lambda_arn = aws_lambda_function.<<<<example.arn>>>>>>
#
#   rotation_rules {
#     automatically_after_days = var.db_password_rotation_period
#   }
# }


# RDS database

resource "aws_db_instance" "appdb1" {
  allocated_storage                     = var.allocated_storage
  db_name                               = var.application_name
  identifier                            = "${var.identifier_name}-${var.environment}-database"
  engine                                = var.engine
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  allow_major_version_upgrade           = var.allow_major_version_upgrade
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  storage_type                          = var.storage_type
  iops                                  = var.iops
  backup_retention_period               = var.backup_retention_period
  backup_window                         = var.backup_window
  maintenance_window                    = var.maintenance_window
  character_set_name                    = var.character_set_name
  multi_az                              = var.multi_az
  username                              = var.username
  password                              = random_password.rds_password.result
  vpc_security_group_ids                = [aws_security_group.laalz-secgroup.id, aws_security_group.vpc-secgroup.id]
  skip_final_snapshot                   = false
  final_snapshot_identifier             = "${var.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name                  = aws_db_parameter_group.parameter_group_19.name
  option_group_name                     = aws_db_option_group.option_group_19.name
  db_subnet_group_name                  = aws_db_subnet_group.subnet_group.name
  license_model                         = var.license_model
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  deletion_protection                   = var.deletion_protection
  copy_tags_to_snapshot                 = true
  storage_encrypted                     = true
  apply_immediately                     = true
  snapshot_identifier                   = var.snapshot_arn
  tags = var.tags

  timeouts {
    create = "60m"
    delete = "2h"
  }

}

# Security Group

resource "aws_security_group" "cloud_platform_sec_group" {
  name        = "cloud-platform-sec-group"
  description = "RDS access from Cloud Platform via Transit gateway"
  vpc_id      = var.vpc_shared_id

  ingress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.cloud_platform_cidr]
  }

  egress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.cloud_platform_cidr]
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-transit-gateway-sec-group"
  }
}

resource "aws_security_group" "vpc_sec_group" {
  name        = "ecs-sec-group"
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
    Name = "${var.application_name}-${var.environment}-vpc-sec-group"
  }
}
