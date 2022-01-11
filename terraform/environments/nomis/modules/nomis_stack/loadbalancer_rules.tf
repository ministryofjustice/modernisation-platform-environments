resource "aws_lb_target_group" "weblogic" {

  name_prefix          = var.stack_name
  port                 = "7777" # port on which targets receive traffic
  protocol             = "HTTPS"
  target_type          = "ip"
  deregistration_delay = "30"
  vpc_id               = data.aws_vpc.shared_vpc.id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled             = true
    interval            = "30"
    healthy_threshold   = "3"
    matcher             = "200-399"
    path                = "/keepalive.htm"
    port                = "7777"
    timeout             = "5"
    unhealthy_threshold = "5"
  }

  # access_logs { maybe we want this?
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = merge(
    local.tags,
    {
      Name = "weblogic-${var.stack_name}-tg"
    },
  )
}

resource "aws_lb_target_group_attachment" "weblogic" {
  target_group_arn = aws_lb_target_group.weblogic.arn
  target_id        = aws_instance.weblogic_server.private_ip
  port             = "7777"
}

resource "aws_lb_listener_rule" "weblogic" {
  listener_arn = var.load_balancer_listener_arn
  priority     = 99

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.weblogic.arn
      }
      # stickiness {
      #   enabled  = true
      #   duration = 600
      # }
    }
  }

  condition {
    host_header {
      values = ["${var.application_name}-${var.stack_name}.${var.business_unit}-${var.environment}.modernisation-platform.service.justice.gov.uk"]
    }
  }
}