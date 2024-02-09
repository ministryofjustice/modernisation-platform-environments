resource "aws_lb_target_group" "this" {
  # checkov:skip=CKV_AWS_261

  name                 = "${var.env_name}-${var.name}"
  port                 = var.ecs_service_port
  protocol             = var.target_group_protocol
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
}

resource "aws_lb_listener_rule" "alb" {
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
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener_rule" "services_alb" {
  for_each     = var.ecs_connectivity_services_alb == null ? toset([]) : toset([for _, v in var.container_port_config : tostring(v.containerPort)])
  listener_arn = var.ecs_connectivity_services_alb_listeners[each.value].arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
  condition {
    host_header {
      values = [aws_route53_record.services_alb_target_group[0].name]
    }
  }
}

resource "aws_route53_record" "services_alb_target_group" {
  count    = var.ecs_connectivity_services_alb == null ? 0 : 1
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_inner_zone_info.zone_id
  name     = "${var.name}.service.${var.env_name}.${var.account_config.dns_suffix}"
  type     = "CNAME"
  alias {
    evaluate_target_health = false
    name                   = var.ecs_connectivity_nlb.dns_name
    zone_id                = var.ecs_connectivity_nlb.zone_id
  }
}
