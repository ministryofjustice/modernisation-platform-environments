
resource "aws_security_group" "ecs_service" {
  name        = "ecs-service-${var.name}-${var.env_name}"
  description = "Security group for the ${var.env_name} ${var.name} service"
  vpc_id      = var.account_config.shared_vpc_id
  tags        = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "ecs_serice_to_elasticache" {
  count                        = var.create_elasticache ? 1 : 0
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "weblogic service to elasticache"
  from_port                    = var.create_elasticache ? var.elasticache_port : null
  to_port                      = var.create_elasticache ? var.elasticache_port : null
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.elasticache[0].id
}

resource "aws_vpc_security_group_egress_rule" "ecs_service_to_db" {
  count                        = var.create_rds ? 1 : 0
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "weblogic service to db"
  from_port                    = var.create_rds ? var.rds_port : var.create_elasticache ? var.elasticache_port : null
  to_port                      = var.create_rds ? var.rds_port : var.create_elasticache ? var.elasticache_port : null
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db[0].id
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_ecs_service" {
  count                        = var.alb_security_group_id == null ? 0 : 1
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "load balancer to ecs service"
  from_port                    = var.container_port_config[0].containerPort
  to_port                      = var.container_port_config[0].containerPort
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.alb_security_group_id
}

resource "aws_security_group_rule" "ecs_service_tls_egress" {
  description       = "Allow all outbound traffic to any IPv4 address on 443"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service.id
}

resource "aws_security_group_rule" "all_cluster_to_ecs_service_tcp" {
  for_each                 = toset([for _, v in var.container_port_config : tostring(v.containerPort)])
  description              = "In from ECS cluster"
  security_group_id        = aws_security_group.ecs_service.id
  type                     = "ingress"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  source_security_group_id = var.cluster_security_group_id
}

resource "aws_security_group_rule" "bastion_to_ecs_service_tcp" {
  for_each                 = toset([for _, v in var.container_port_config : tostring(v.containerPort)])
  description              = "In from Bastion"
  security_group_id        = aws_security_group.ecs_service.id
  type                     = "ingress"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  source_security_group_id = var.bastion_sg_id
}

resource "aws_vpc_security_group_ingress_rule" "nlb_to_ecs_service" {
  count                        = length(var.container_port_config) == 0 ? 0 : 1
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "network load balancer to ecs service"
  from_port                    = var.container_port_config[0].containerPort
  to_port                      = var.container_port_config[0].containerPort
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.delius_microservices_service_nlb.id
}

resource "aws_vpc_security_group_ingress_rule" "custom_rules" {
  for_each                     = { for index, rule in var.ecs_service_ingress_security_group_ids : index => rule }
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "custom rule"
  from_port                    = each.value.port
  to_port                      = each.value.port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.referenced_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "custom_rules" {
  for_each                     = { for index, rule in var.ecs_service_egress_security_group_ids : index => rule }
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "custom rule"
  from_port                    = each.value.port
  to_port                      = each.value.port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.referenced_security_group_id
}
