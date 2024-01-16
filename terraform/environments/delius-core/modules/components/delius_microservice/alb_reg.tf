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

output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}
