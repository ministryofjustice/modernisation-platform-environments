# API Load Balancer Configuration
resource "aws_lb" "sftp_load_balancer" {
  name               = "${local.sftp_suffix}-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = data.aws_subnets.shared-private.ids

  security_groups = [aws_security_group.sftp_load_balancer.id]

  access_logs {
    bucket  = data.aws_s3_bucket.logging_bucket.id
    prefix  = "${local.sftp_suffix}-lb"
    enabled = true
  }

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-lb" }
  )
}

resource "aws_lb_target_group" "sftp_target_group" {
  name                 = "${local.sftp_suffix}-tg"
  port                 = local.application_data.accounts[local.environment].api_server_port
  protocol             = "HTTPS"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 7200
    enabled         = true
  }

  health_check {
    path                = "/actuator/health"
    port                = local.application_data.accounts[local.environment].api_server_port
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTPS"
    unhealthy_threshold = "2"
    matcher             = "200"
    timeout             = "5"
  }

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-tg" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Redirect all traffic from the lb to the target group
resource "aws_lb_listener" "sftp_listener" {
  load_balancer_arn = aws_lb.sftp_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate.external_sftp.arn

  default_action {
    target_group_arn = aws_lb_target_group.sftp_target_group.id
    type             = "forward"
  }
}