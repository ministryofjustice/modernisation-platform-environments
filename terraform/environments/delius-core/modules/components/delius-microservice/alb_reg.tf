resource "aws_lb_listener" "listener" {
  load_balancer_arn = var.microservice_lb_arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_lb_target_group.this.id
    type             = "forward"
  }
}



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
    type = "lb_cookie"
  }

  health_check {
    path                = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
    healthy_threshold   = "5"
    interval            = "300"
    protocol            = "HTTP"
    unhealthy_threshold = "5"
    matcher             = "200-499"
    timeout             = "5"
  }
}