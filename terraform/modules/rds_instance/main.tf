#------------------------------------------------------------------------------
# RDS DB Instance
#------------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  identifier = var.instance.identifier

  engine            = var.instance.engine
  engine_version    = var.instance.engine_version
  instance_class    = var.instance.instance_class
  allocated_storage = var.instance.allocated_storage
  storage_type      = var.instance.storage_type
  storage_encrypted = var.instance.storage_encrypted
  kms_key_id        = var.instance.kms_key_id
  license_model     = var.instance.license_model

  name                                = var.instance.name
  username                            = var.instance.username
  password                            = var.instance.password
  port                                = var.instance.port
  iam_database_authentication_enabled = var.instance.iam_database_authentication_enabled

  replicate_source_db = var.instance.replicate_source_db

  snapshot_identifier = var.instance.snapshot_identifier

  vpc_security_group_ids = [var.instance.vpc_security_group_ids]
  db_subnet_group_name   = var.instance.db_subnet_group_name
  parameter_group_name   = var.instance.parameter_group_name
  option_group_name      = var.instance.option_group_name

  availability_zone   = var.instance.availability_zone
  multi_az            = var.instance.multi_az
  iops                = var.instance.iops
  publicly_accessible = var.instance.publicly_accessible
  monitoring_interval = var.instance.monitoring_interval
  monitoring_role_arn = var.instance.monitoring_role_arn

  allow_major_version_upgrade = var.instance.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.instance.auto_minor_version_upgrade
  apply_immediately           = var.instance.apply_immediately
  maintenance_window          = var.instance.maintenance_window
  skip_final_snapshot         = var.instance.skip_final_snapshot
  copy_tags_to_snapshot       = var.instance.copy_tags_to_snapshot
  final_snapshot_identifier   = var.instance.final_snapshot_identifier

  backup_retention_period = var.instance.backup_retention_period
  backup_window           = var.instance.backup_window

  character_set_name = var.instance.character_set_name

  tags = merge(var.tags, map("Name", format("%s", var.identifier)))
 
  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
}

resource "aws_db_instance_automated_backups_replication" "this" {
  source_db_instance_arn = aws_db_instance.this.arn
  retention_period       = var.db_instance_automated_backups_replication
}

#------------------------------------------------------------------------------
# OPTION GROUPS
#------------------------------------------------------------------------------

resource "aws_db_option_group" "this" {
  name                     = var.db_option_group.name
  option_group_description = var.db_option_group.description
  engine_name              = var.db_option_group.engine_name
  major_engine_version     = var.db_option_group.major_engine_version

  dynamic "option" {
    for_each = var.db_option_group.options

    content {
      option_name = db_option_group.options.value["name"]

      dynamic "option_settings" {
        for_each = db_option_group.options.value["settings"]
        content {
          name  = settings.value["name"]
          value = settings.value["value"]
        }
      }
    }
  }
}

#------------------------------------------------------------------------------
# PARAMETER GROUPS
#------------------------------------------------------------------------------

resource "aws_db_parameter_group" "this" {
  name   = "rds-pg"
  family = "mysql5.6"

  dynamic "parameter" {
    for_each = var.db_parameter_group.parameter
    content {
      name  = parameter.value["name"]
      value = parameter.value["value"]
    }
  }
}

#------------------------------------------------------------------------------
# PROXY OPTIONS
#------------------------------------------------------------------------------

resource "aws_db_proxy" "this" {
  name                   = var.db_proxy.name
  debug_logging          = var.db_proxy.debug_logging
  engine_family          = var.db_proxy.engine_family
  idle_client_timeout    = var.db_proxy.idle_client_timeout
  require_tls            = var.db_proxy.require_tls
  role_arn               = var.db_proxy.role_arn
  vpc_security_group_ids = var.db_proxy.vpc_security_group_ids
  vpc_subnet_ids         = var.db_proxy.vpc_subnet_ids

  auth {
    auth_scheme = var.db_proxy.auth.auth_scheme
    description = var.db_proxy.auth.description
    iam_auth    = var.db_proxy.auth.iam_auth
    secret_arn  = var.db_proxy.auth.secret_arn
  }

  tags = merge(local.tags, {
    Name = var.instance.name
  })
}

resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = var.db_proxy_default_target_group.db_proxy_name

  connection_pool_config {
    connection_borrow_timeout    = var.db_proxy_default_target_group.connection_pool_config.connection_borrow_timeout
    init_query                   = var.db_proxy_default_target_group.connection_pool_config.init_query
    max_connections_percent      = var.db_proxy_default_target_group.connection_pool_config.max_connections_percent
    max_idle_connections_percent = var.db_proxy_default_target_group.connection_pool_config.max_idle_connections_percent
    session_pinning_filters      = var.db_proxy_default_target_group.connection_pool_config.session_pinning_filters
  }
}