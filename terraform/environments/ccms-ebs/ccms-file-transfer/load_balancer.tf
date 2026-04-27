# API Load Balancer Configuration
resource "aws_lb" "sftp_bc_load_balancer" {
  name               = "${local.application_name}-sftp-bc-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = data.aws_subnets.shared-private.ids

  security_groups = [aws_security_group.sftp_bc_load_balancer.id]

  access_logs {
    bucket  = data.aws_s3_bucket.logging_bucket.id
    prefix  = "${local.application_name}-sftp-bc-lb"
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-bc-%s-lb", local.application_name, local.environment)) }
  )
}

resource "aws_lb_target_group" "sftp_bc_target_group" {
  name                 = "${local.application_name}-sftp-bc-tg"
  port                 = local.application_data.accounts[local.environment].api_server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 7200
    enabled         = true
  }

  health_check {
    path                = "/"
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200"
    timeout             = "5"
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-bc-%s-tg", local.application_name, local.environment)) }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Redirect all traffic from the lb to the target group
resource "aws_lb_listener" "sftp_bc_listener" {
  load_balancer_arn = aws_lb.sftp_bc_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate.external_sftp_bc.arn

  default_action {
    target_group_arn = aws_lb_target_group.sftp_bc_target_group.id
    type             = "forward"
  }
}