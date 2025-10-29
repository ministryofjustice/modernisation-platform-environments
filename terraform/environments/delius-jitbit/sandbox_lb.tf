locals {
  sandbox_target_groups = {
    blue  = aws_lb_target_group.target_group_fargate_sandbox_blue[0].id
    green = aws_lb_target_group.target_group_fargate_sandbox_green[0].id
  }

  active_sandbox_colour = local.is-development ? data.aws_ssm_parameter.sandbox_active_deployment_colour[0].value : null

  sandbox_active_target_group_arn = lookup(
    local.sandbox_target_groups,
    local.active_sandbox_colour,
    null
  )
}

#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "external_sandbox" {
  # checkov:skip=CKV_AWS_91
  # checkov:skip=CKV2_AWS_28
  count = local.is-development ? 1 : 0

  name               = "${local.application_name}-lb-sandbox"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  subnets            = data.aws_subnets.shared-public.ids

  enable_deletion_protection = true
  drop_invalid_header_fields = true

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_lb_listener" "listener_sandbox" {
  count = local.is-development ? 1 : 0

  load_balancer_arn = aws_lb.external_sandbox[0].id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external.arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = local.sandbox_active_target_group_arn
    type             = "forward"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_lb_listener_rule" "listener_rule_sandbox_blue" {
  count        = local.is-development ? 1 : 0
  listener_arn = aws_lb_listener.listener_sandbox[0].arn
  priority     = 20

  action {
    target_group_arn = aws_lb_target_group.target_group_fargate_sandbox_blue[0].arn
    type             = "forward"
  }

  condition {
    host_header {
      values = ["blue-${local.sandbox_app_url}"]
    }
  }
}

resource "aws_lb_listener_rule" "listener_rule_sandbox_green" {
  count        = local.is-development ? 1 : 0
  listener_arn = aws_lb_listener.listener_sandbox[0].arn
  priority     = 30

  action {
    target_group_arn = aws_lb_target_group.target_group_fargate_sandbox_green[0].arn
    type             = "forward"
  }

  condition {
    host_header {
      values = ["green-${local.sandbox_app_url}"]
    }
  }
}

resource "aws_lb_target_group" "target_group_fargate_sandbox_blue" {
  # checkov:skip=CKV_AWS_261

  count = local.is-development ? 1 : 0

  name                 = "${local.application_name}-sandbox-blue"
  port                 = local.app_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path                = "/User/Login?ReturnUrl=%2f"
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-sandbox-blue"
    }
  )
}

resource "aws_lb_target_group" "target_group_fargate_sandbox_green" {
  # checkov:skip=CKV_AWS_261

  count = local.is-development ? 1 : 0

  name                 = "${local.application_name}-sandbox-green"
  port                 = local.app_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path                = "/User/Login?ReturnUrl=%2f"
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-sandbox-green"
    }
  )
}