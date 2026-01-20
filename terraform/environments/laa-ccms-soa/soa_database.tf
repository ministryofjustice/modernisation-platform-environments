resource "aws_db_subnet_group" "soa" {
  name_prefix = "main"
  subnet_ids  = data.aws_subnets.shared-data.ids

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_option_group" "soa_oracle_19" {
  name_prefix          = "soa-db-option-group"
  engine_name          = "oracle-ee"
  major_engine_version = "19"

  option {
    option_name = "JVM"
  }

  option {
    option_name = "S3_INTEGRATION"
    port        = 0
    version     = "1.0"
  }

  #######################################
  # OEM Agent Option (Corrected)
  #######################################
  option {
    option_name = "OEM_AGENT"

    # Required: AGENT_PORT (defaults to 3872 if you like)
    port    = 3872

    # Required: AGENT_VERSION (pick one supported in your region)
    # e.g. 13.5.0.0.v2 – check docs / console for allowed values
    version = "13.5.0.0.v2"

    # Required: security group that OMS can reach
    vpc_security_group_memberships = [
      aws_security_group.soa_db.id
    ]

    # Required: OMS host
    option_settings {
      name  = "OMS_HOST"
      value = "laa-oem-app.laa-development.modernisation-platform.service.justice.gov.uk"
    }

    # Required: OMS_PORT (HTTPS upload port on OMS, typically 4903)
    option_settings {
      name  = "OMS_PORT"
      value = "4903"
    }

    # Required: registration password
    option_settings {
      name  = "AGENT_REGISTRATION_PASSWORD"
      value = jsondecode(
        data.aws_secretsmanager_secret_version.oem_agent_credentials.secret_string
      ).password
    }

    # Optional but recommended in many setups:
    # option_settings {
    #   name  = "MINIMUM_TLS_VERSION"
    #   value = "TLSv1.2"
    # }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_db_instance" "soa_db" {
  identifier                          = "soa-db"
  allocated_storage                   = local.application_data.accounts[local.environment].soa_db_storage_gb
  auto_minor_version_upgrade          = local.application_data.accounts[local.environment].soa_db_minor_version_upgrade_allowed #--This needs to be set to true if using a JVM in the above option group
  storage_type                        = "gp2"
  engine                              = "oracle-ee"
  engine_version                      = local.application_data.accounts[local.environment].soa_db_version
  instance_class                      = local.application_data.accounts[local.environment].soa_db_instance_type
  multi_az                            = local.application_data.accounts[local.environment].soa_db_deploy_to_multi_azs
  db_name                             = "SOADB"
  username                            = local.application_data.accounts[local.environment].soa_db_user
  password                            = data.aws_secretsmanager_secret_version.soa_password.secret_string
  port                                = "1521"
  kms_key_id                          = data.aws_kms_key.rds_shared.arn
  storage_encrypted                   = true
  license_model                       = "bring-your-own-license"
  iam_database_authentication_enabled = false

  vpc_security_group_ids = [
    aws_security_group.soa_db.id
  ]

  backup_retention_period = 30
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  character_set_name      = "AL32UTF8"
  deletion_protection     = local.application_data.accounts[local.environment].soa_db_deletion_protection
  db_subnet_group_name    = aws_db_subnet_group.soa.id
  option_group_name       = aws_db_option_group.soa_oracle_19.id

  tags = merge(
    local.tags,
    { instance-scheduling = "skip-scheduling" }
  )

  enabled_cloudwatch_logs_exports = [
    "alert",
    "audit",
    "listener"
  ]

  timeouts {
    create = "40m"
    delete = "40m"
    update = "80m"
  }
}
