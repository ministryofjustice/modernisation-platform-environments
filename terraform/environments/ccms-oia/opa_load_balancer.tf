########################################
# Application Load Balancer for OPAHUB
########################################

resource "aws_lb" "opahub" {
  name               = "${local.opa_app_name}-lb"
  load_balancer_type = "application"
  internal           = true

  subnets = data.aws_subnets.shared-private.ids

  security_groups = [aws_security_group.opahub_load_balancer.id]
  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = "${local.opa_app_name}-lb"
    enabled = true
  }
  tags = merge(local.tags,
    { Name = lower(format("%s-lb", local.opa_app_name)) }
  )
  depends_on = [module.s3-bucket-logging]
}

########################################
# Target Group
########################################
resource "aws_lb_target_group" "opahub_target_group" {
  name                 = "${local.opa_app_name}-tg"
  port                 = local.application_data.accounts[local.environment].opa_server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path                = "/opa/opa-hub/manager"
    healthy_threshold   = 5
    interval            = 120
    protocol            = "HTTP"
    unhealthy_threshold = 5
    matcher             = "200"
    timeout             = 5
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-tg", local.opa_app_name)) }
  )
}

########################################
# Listeners
########################################

resource "aws_lb_listener" "opahub_listener" {
  load_balancer_arn = aws_lb.opahub.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    target_group_arn = aws_lb_target_group.opahub_target_group.id
    type             = "forward"
  }
}

# # Temp only required on first install
resource "aws_lb_listener" "opahub_listener_7001" {
  load_balancer_arn = aws_lb.opahub.id
  port              = "7001"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.opahub_target_group.id
    type             = "forward"
  }
}
