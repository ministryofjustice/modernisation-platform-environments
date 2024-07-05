resource "random_id" "suffix" {
  keepers = {
    protocol         = var.target_group_protocol
    port             = var.container_port_config[0].containerPort
    protocol_version = var.target_group_protocol_version
  }

  byte_length = 2
}

## ALB target group and listener rule
resource "aws_lb_target_group" "frontend" {
  count = var.microservice_lb != null ? 1 : 0
  # checkov:skip=CKV_AWS_261
  # https://github.com/hashicorp/terraform-provider-aws/issues/16889
  name                 = "${var.env_name}-${var.name}-${random_id.suffix.hex}"
  port                 = random_id.suffix.keepers.port
  protocol             = random_id.suffix.keepers.protocol
  protocol_version     = random_id.suffix.keepers.protocol_version
  vpc_id               = var.account_config.shared_vpc_id
  target_type          = "ip"
  deregistration_delay = 30
  tags                 = var.tags

  stickiness {
    enabled = var.alb_stickiness_enabled
    type    = var.alb_stickiness_type
  }

  health_check {
    path                = var.health_check_path
    healthy_threshold   = "5"
    interval            = var.health_check_interval
    protocol            = "HTTP"
    unhealthy_threshold = "5"
    matcher             = "200-499"
    timeout             = "5"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "alb_path" {
  count        = var.alb_listener_rule_paths != null ? 1 : 0
  listener_arn = var.microservice_lb_https_listener_arn
  priority     = var.alb_listener_rule_priority != null ? var.alb_listener_rule_priority : null
  condition {
    path_pattern {
      values = var.alb_listener_rule_paths
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend[0].arn
  }
}

resource "aws_lb_listener_rule" "alb_header" {
  count        = var.alb_listener_rule_host_header != null ? 1 : 0
  listener_arn = var.microservice_lb_https_listener_arn
  priority     = var.alb_listener_rule_priority != null ? var.alb_listener_rule_priority : null
  condition {
    host_header {
      values = [var.alb_listener_rule_host_header]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend[0].arn
  }
}

resource "aws_route53_record" "alb_r53_record" {
  count    = var.alb_listener_rule_host_header != null ? 1 : 0
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_external_zone.zone_id
  name     = var.alb_listener_rule_host_header
  type     = "A"
  alias {
    evaluate_target_health = false
    name                   = var.microservice_lb.dns_name
    zone_id                = var.microservice_lb.zone_id
  }
}

# NLB for service interconnectivity

resource "aws_lb" "delius_microservices" {
  name                       = "${var.name}-${var.env_name}-service-nlb"
  internal                   = true
  load_balancer_type         = "network"
  security_groups            = [aws_security_group.delius_microservices_service_nlb.id]
  subnets                    = var.account_config.private_subnet_ids
  enable_deletion_protection = false
  tags                       = var.tags
}

resource "aws_security_group" "delius_microservices_service_nlb" {
  name        = "${var.name}-${var.env_name}-service-nlb"
  description = "Security group for delius microservices service load balancer"
  vpc_id      = var.account_info.vpc_id
  tags        = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_vpc" {
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  ip_protocol       = "-1"
  security_group_id = aws_security_group.delius_microservices_service_nlb.id
}

resource "aws_vpc_security_group_egress_rule" "nlb_to_ecs_service" {
  for_each                     = toset([for _, v in var.container_port_config : tostring(v.containerPort)])
  ip_protocol                  = "TCP"
  from_port                    = each.value
  to_port                      = each.value
  security_group_id            = aws_security_group.delius_microservices_service_nlb.id
  referenced_security_group_id = aws_security_group.ecs_service.id
}

resource "aws_lb_target_group" "service" {
  for_each = toset([for _, v in var.container_port_config : tostring(v.containerPort)])

  name        = "${var.name}-${var.env_name}-at-${each.value}"
  target_type = "ip"
  port        = each.value
  protocol    = "TCP"
  vpc_id      = var.account_info.vpc_id
  tags        = var.tags
}

resource "aws_lb_listener" "services" {
  for_each = toset([for _, v in var.container_port_config : tostring(v.containerPort)])

  load_balancer_arn = aws_lb.delius_microservices.arn
  port              = each.value
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.value].arn
  }
}

resource "aws_route53_record" "services_nlb_r53_record" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_inner_zone_info.zone_id
  name     = "${var.name}.service.${var.env_name}.${var.account_config.dns_suffix}"
  type     = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_lb.delius_microservices.dns_name
    zone_id                = aws_lb.delius_microservices.zone_id
  }
}
