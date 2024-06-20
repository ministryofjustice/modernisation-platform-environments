resource "aws_elasticache_subnet_group" "this" {
  count      = var.create_elasticache ? 1 : 0
  name       = "elasticache-subnet-group-${var.name}-${var.env_name}"
  subnet_ids = var.account_config.ordered_private_subnet_ids
  tags       = var.tags
}

resource "aws_elasticache_cluster" "this" {
  count                      = var.create_elasticache ? 1 : 0
  cluster_id                 = "${var.name}-${var.env_name}"
  engine                     = var.elasticache_engine
  node_type                  = var.elasticache_node_type
  num_cache_nodes            = var.elasticache_num_cache_nodes
  parameter_group_name       = var.elasticache_parameter_group_name
  engine_version             = var.elasticache_engine_version
  port                       = var.elasticache_port
  subnet_group_name          = aws_elasticache_subnet_group.this[0].name
  apply_immediately          = var.elasticache_apply_immediately
  auto_minor_version_upgrade = true
  final_snapshot_identifier  = var.elasticache_engine == "redis" ? "final-redis-${var.name}-${var.env_name}" : null
  maintenance_window         = var.maintenance_window
  security_group_ids         = [aws_security_group.elasticache[0].id]
}

# module "elasticache_default_user_password" {
#   count = var.create_elasticache ? 1 : 0
#   source                   = "../secret"
#   name                     = "${var.name}-elasticache-password"
#   description              = "Elasticache Default User Password"
#   tags                     = var.tags
#   kms_key_id               = var.account_config.kms_keys.general_shared
#   generate_random_password = true
# }

# data "aws_secretsmanager_secret_version" "elasticache_default_user_password" {
#   count = var.create_elasticache ? 1 : 0
#   secret_id = module.elasticache_default_user_password[0].secret.id
# }

# resource "aws_elasticache_user" "app_default" {
#   count = var.create_elasticache ? 1 : 0

#   user_id       = var.name
#   user_name     = var.name
#   access_string = "on ~* +@all"
#   engine        = "REDIS"

#   authentication_mode {
#     type      = "password"
#     passwords = [data.aws_secretsmanager_secret_version.elasticache_default_user_password[0].secret_string]
#   }
# }

# resource "aws_elasticache_user_group" "app_default" {
#   count = var.create_elasticache ? 1 : 0

#   user_group_id = var.name
#   engine        = "REDIS"
#   user_ids      = ["default", aws_elasticache_user.app_default[0].id]
#   lifecycle {
#     ignore_changes = [user_ids]
#   }
# }


resource "aws_security_group" "elasticache" {
  count       = var.create_elasticache ? 1 : 0
  name        = "${var.name}-${var.env_name}-elasticache-security-group"
  description = "controls access to elasticache"
  vpc_id      = var.account_config.shared_vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${var.env_name}-database_security_group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "elasticache_to_ecs_service" {
  count                        = var.create_elasticache ? 1 : 0
  security_group_id            = aws_security_group.elasticache[0].id
  description                  = "elasticache to ecs service"
  from_port                    = var.elasticache_port
  to_port                      = var.elasticache_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_service.id
}

resource "aws_elasticache_parameter_group" "this" {
  name   = "${var.name}-${var.env_name}"
  family = var.elasticache_parameter_group_family

  dynamic "parameter" {
    for_each = var.elasticache_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}
