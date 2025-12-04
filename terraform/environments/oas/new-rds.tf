##################################################################################################################
# Random Secret for the DB Password to be used for installation of OAS only
# The password is generated once and persists across Terraform runs unless the RDS instance is recreated
# The lifecycle ignore_changes prevents accidental password regeneration
# The keepers ensure the password is only recreated when the RDS instance identifier changes
##################################################################################################################

resource "random_password" "rds_password_new" {
  count   = local.environment == "preproduction" ? 1 : 0
  length  = 16
  special = false

  keepers = {
    # Regenerate password only when RDS instance is recreated (identifier changes)
    rds_identifier = "${local.application_name}-${local.environment}"
  }

  lifecycle {
    ignore_changes = [
      keepers
    ]
  }
}


resource "aws_secretsmanager_secret" "rds_password_secret_new" {
  count       = local.environment == "preproduction" ? 1 : 0
  name        = "${local.application_name}/app/db-master-password"
  description = "This secret has a dynamically generated password."
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/app/db-master-password" },
  )
}


resource "aws_secretsmanager_secret_version" "rds_password_secret_version_new" {
  count     = local.environment == "preproduction" ? 1 : 0
  secret_id = aws_secretsmanager_secret.rds_password_secret_new[0].id
  secret_string = jsonencode(
    {
      username = local.application_data.accounts[local.environment].username
      password = random_password.rds_password_new[0].result
    }
  )

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}


##################################################################################################################
### RDS Subnet Group
##################################################################################################################
resource "aws_db_subnet_group" "appdbsubnetgroup_new" {
  count = local.environment == "preproduction" ? 1 : 0

  name       = "appdbsubnetgroup"
  subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-subnetgroup"
      Keep = "true"
    }
  )
}


##################################################################################################################
### RDS Parameter Group
##################################################################################################################
resource "aws_db_parameter_group" "appdbparametergroup19_new" {
  count = local.environment == "preproduction" ? 1 : 0

  name        = "appdbparametergroup19"
  family      = "oracle-ee-19"
  description = "${local.application_name}-${local.environment}-parametergroup"

  parameter {
    name  = "remote_dependencies_mode"
    value = "SIGNATURE"
  }

  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "10"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-parametergroup"
    }
  )
}


##################################################################################################################
### RDS Option Group
##################################################################################################################
resource "aws_db_option_group" "appdboptiongroup19_new" {
  count = local.environment == "preproduction" ? 1 : 0

  name                     = "appdboptiongroup19"
  option_group_description = "${local.application_name}-${local.environment}-optiongroup"
  engine_name              = local.application_data.accounts[local.environment].engine
  major_engine_version     = "19"

  option {
    option_name = "STATSPACK"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-optiongroup"
      Keep = "true"
    }
  )
}


##################################################################################################################
### OAS RDS INSTANCE - Preproduction only for now, will we extended to prod later and then to all env's 
##################################################################################################################
resource "aws_db_instance" "oas_rds_instance" {
  count = local.environment == "preproduction" ? 1 : 0

  # Instance identification
  identifier     = "${local.application_name}-${local.environment}"
  db_name        = "${local.application_name}-${local.environment}"
  engine         = local.application_data.accounts[local.environment].engine
  engine_version = local.application_data.accounts[local.environment].engine_version
  instance_class = local.application_data.accounts[local.environment].instance_class
  license_model  = local.application_data.accounts[local.environment].license_model

  # Storage configuration
  allocated_storage = local.application_data.accounts[local.environment].allocated_storage
  storage_type      = local.application_data.accounts[local.environment].storage_type
  storage_encrypted = true
  kms_key_id        = data.aws_kms_key.rds_shared.arn

  # Database configuration
  character_set_name = local.application_data.accounts[local.environment].character_set_name
  username           = local.application_data.accounts[local.environment].username
  password           = random_password.rds_password_new[0].result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.appdbsubnetgroup_new[0].name
  vpc_security_group_ids = [aws_security_group.rds_sg[0].id]
  availability_zone      = local.application_data.accounts[local.environment].availability_zone
  multi_az               = local.application_data.accounts[local.environment].multi_az

  # Backup configuration
  backup_retention_period   = local.application_data.accounts[local.environment].backup_retention_period
  backup_window             = local.application_data.accounts[local.environment].backup_window
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  copy_tags_to_snapshot     = true

  # Maintenance configuration
  maintenance_window          = local.application_data.accounts[local.environment].maintenance_window
  auto_minor_version_upgrade  = local.application_data.accounts[local.environment].auto_minor_version_upgrade
  allow_major_version_upgrade = local.application_data.accounts[local.environment].allow_major_version_upgrade
  apply_immediately           = true

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.appdbparametergroup19_new[0].name
  option_group_name    = aws_db_option_group.appdboptiongroup19_new[0].name

  # Security configuration
  deletion_protection = local.application_data.accounts[local.environment].deletion_protection

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-database" }
  )

  timeouts {
    create = "60m"
    delete = "2h"
  }
}