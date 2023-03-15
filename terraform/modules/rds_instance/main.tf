#------------------------------------------------------------------------------
# RDS
#------------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  allocated_storage     = var.instance.allocated_storage
  db_name               = var.instance.name
  engine                = var.instance.engine
  engine_version        = var.instance.engine_version
  instance_class        = var.instance.instance_class
  username              = var.instance.username
  password              = var.instance.password
  parameter_group_name  = var.instance.parameter_group_name
  skip_final_snapshot   = var.instance.skip_final_snapshot
  max_allocated_storage = var.instance.max_allocated_storage
}

resource "aws_db_instance_automated_backups_replication" "this" {
  source_db_instance_arn = aws_db_instance.this.arn
  retention_period       = var.db_instance_automated_backups_replication
}

#------------------------------------------------------------------------------
# OPTION GROUPS
#------------------------------------------------------------------------------

resource "aws_db_option_group" "this" {
  name                     = var.aws_db_option_group.name
  option_group_description = var.aws_db_option_group.description
  engine_name              = var.aws_db_option_group.engine_name
  major_engine_version     = var.aws_db_option_group.major_engine_version

  dynamic "option" {
    for_each = var.aws_db_option_group.options

    content {
      option_name = aws_db_option_group.options.value["name"]

      dynamic "option_settings" {
        for_each = aws_db_option_group.options.value["settings"]
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
    for_each = var.aws_db_parameter_group.parameter
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