########################################
# Application Load Balancer for Adaptor
########################################

resource "aws_lb" "adaptor" {
  name               = "${local.adaptor_app_name}-lb"
  load_balancer_type = "application"
  internal           = true

  subnets = data.aws_subnets.shared-private.ids

  security_groups = [aws_security_group.adaptor_load_balancer.id]

  tags = merge(local.tags,
    { Name = lower(format("%s-lb", local.adaptor_app_name)) }
  )
}

########################################
# Target Group
########################################
resource "aws_lb_target_group" "adaptor_target_group" {
  name                 = "${local.adaptor_app_name}-tg"
  port                 = local.application_data.accounts[local.environment].adaptor_server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 5
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 5
    matcher             = "200"
    timeout             = 5
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-tg", local.adaptor_app_name)) }
  )
}

########################################
# Listeners
########################################

resource "aws_lb_listener" "adaptor_listener" {
  load_balancer_arn = aws_lb.adaptor.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    target_group_arn = aws_lb_target_group.adaptor_target_group.id
    type             = "forward"
  }
}
