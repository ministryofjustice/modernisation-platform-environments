################################################################################
# RDS Proxy
################################################################################

data "aws_region" "current" {}

resource "aws_security_group" "rds_proxy" {
  name_prefix = "RDS Proxy Security Group"
  description = "Controls access to the RDS Proxy for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(local.all_tags,
    {
      Name = "RDS Proxy Security Group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_proxy_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.rds_proxy.id
  description              = "RDS Proxy to Aurora PostgreSQL"
}

resource "aws_security_group_rule" "rds_proxy_egress_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_proxy.id
  source_security_group_id = aws_security_group.rds.id
  description              = "RDS Proxy to Aurora PostgreSQL"
}

resource "aws_iam_role" "rds_proxy" {
  name = "${var.name}-rds-proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
    }]
  })

  tags = local.all_tags
}

resource "aws_iam_role_policy" "rds_proxy_secrets" {
  name = "${var.name}-rds-proxy-secrets"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = var.proxy_secret_arn
      },
      {
        Effect = "Allow"
        Action = "kms:Decrypt"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_db_proxy" "rds_proxy" {
  name                = "${var.name}-proxy"
  engine_family       = "POSTGRESQL"
  idle_client_timeout = var.proxy_idle_client_timeout
  require_tls         = true
  debug_logging       = var.proxy_debug_logging
  role_arn            = aws_iam_role.rds_proxy.arn

  vpc_subnet_ids         = var.database_subnets
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "REQUIRED"
    secret_arn  = var.proxy_secret_arn
  }

  tags = local.all_tags
}

resource "aws_db_proxy_default_target_group" "rds_proxy" {
  db_proxy_name = aws_db_proxy.rds_proxy.name

  connection_pool_config {
    max_connections_percent      = var.proxy_max_connections_percent
    max_idle_connections_percent = var.proxy_max_idle_connections_percent
    connection_borrow_timeout    = var.proxy_connection_borrow_timeout
  }
}

resource "aws_db_proxy_target" "aurora_cluster" {
  db_proxy_name         = aws_db_proxy.rds_proxy.name
  target_group_name     = aws_db_proxy_default_target_group.rds_proxy.name
  db_cluster_identifier = module.aurora.cluster_id
}
