##############################################################
# S3 Bucket Creation
# For root account id, refer below link
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
##############################################################

data "aws_acm_certificate" "equip_cert" {
  domain   = "equip.service.justice.gov.uk"
  statuses = ["ISSUED"]
}

#Load balancer needs to be publically accessible
#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "citrix_alb" {

  name               = format("alb-%s-%s-citrix", local.application_name, local.environment)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id]

  enable_deletion_protection = true
  drop_invalid_header_fields = true
  enable_waf_fail_open       = true
  ip_address_type            = "ipv4"

  tags = merge(local.tags,
    { Name = format("alb-%s-%s-citrix", local.application_name, local.environment)
      Role = "Equip public load balancer"
    }
  )

  access_logs {
    bucket  = aws_s3_bucket.this.id
    enabled = "true"
  }

}

resource "aws_lb_target_group" "lb_tg_gateway" {
  name        = "tg-gateway"
  target_type = "ip"
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.shared.id
  port        = "443"

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTPS"
    port                = 443
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = local.tags
}

resource "aws_lb_target_group" "lb_tg_equip-portal" {
  name        = "tg-equip-portal"
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.shared.id
  port        = "80"

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTP"
    port                = 80
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = local.tags
}

resource "aws_lb_target_group" "lb_tg_portal" {
  name        = "tg-portal"
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.shared.id
  port        = "80"

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTP"
    port                = 80
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = local.tags
}

resource "aws_lb_target_group" "lb_tg_analytics" {
  name        = "tg-analytics"
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.shared.id
  port        = "8080"

  health_check {
    enabled             = true
    path                = "/spotfire/login.html"
    interval            = 30
    protocol            = "HTTP"
    port                = 8080
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = local.tags
}

resource "aws_lb_target_group_attachment" "lb_tga_gateway" {
  target_group_arn = aws_lb_target_group.lb_tg_gateway.arn
  target_id        = aws_network_interface.adc_vip_interface.private_ip_list[0]
}

resource "aws_lb_target_group_attachment" "lb_tga_equip-portal" {
  target_group_arn = aws_lb_target_group.lb_tg_equip-portal.arn
  target_id        = join("", module.win2012_STD_multiple["COR-A-EQP01"].private_ip)
}

resource "aws_lb_target_group_attachment" "lb_tga_portal" {
  target_group_arn = aws_lb_target_group.lb_tg_portal.arn
  target_id        = join("", module.win2012_STD_multiple["COR-A-EQP01"].private_ip)
}

resource "aws_lb_target_group_attachment" "lb_tga_analytics" {
  target_group_arn = aws_lb_target_group.lb_tg_analytics.arn
  target_id        = join("", module.win2012_STD_multiple["COR-A-SF01"].private_ip)
}

resource "aws_lb_listener" "lb_listener_https" {
  #checkov:skip=CKV_AWS_103
  load_balancer_arn = aws_lb.citrix_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.equip_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.lb_tg_gateway.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "lb_listener_http" {
  load_balancer_arn = aws_lb.citrix_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "equip-portal-equip-service-justice-gov-uk" {
  listener_arn = aws_lb_listener.lb_listener_https.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg_equip-portal.arn
  }
  condition {
    host_header {
      values = ["equip-portal.equip.service.justice.gov.uk"]
    }
  }
}

resource "aws_lb_listener_rule" "gateway-equip-service-justice-gov-uk" {
  listener_arn = aws_lb_listener.lb_listener_https.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg_gateway.arn
  }
  condition {
    host_header {
      values = ["gateway.equip.service.justice.gov.uk"]
    }
  }
}

resource "aws_lb_listener_rule" "portal-equip-service-justice-gov-uk" {
  listener_arn = aws_lb_listener.lb_listener_https.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg_portal.arn
  }
  condition {
    host_header {
      values = ["portal.equip.service.justice.gov.uk"]
    }
  }
}

resource "aws_lb_listener_rule" "analytics-equip-service-justice-gov-uk" {
  listener_arn = aws_lb_listener.lb_listener_https.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg_analytics.arn
  }
  condition {
    host_header {
      values = ["analytics.equip.service.justice.gov.uk"]
    }
  }
}

resource "aws_lb_listener_rule" "equip-analytics-rocstac-com" {
  listener_arn = aws_lb_listener.lb_listener_https.arn
  action {
    type = "redirect"
    redirect {
      host        = "analytics.equip.service.justice.gov.uk"
      status_code = "HTTP_301"
    }
  }
  condition {
    host_header {
      values = ["equip-analytics.rocstac.com"]
    }
  }
}

resource "aws_lb_listener_rule" "equip-gateway-rocstac-com" {
  listener_arn = aws_lb_listener.lb_listener_https.arn
  action {
    type = "redirect"
    redirect {
      host        = "gateway.equip.service.justice.gov.uk"
      status_code = "HTTP_301"
    }
  }
  condition {
    host_header {
      values = ["equip-gateway.rocstac.com"]
    }
  }
}

resource "aws_lb_listener_rule" "equip-portal-rocstac-com" {
  listener_arn = aws_lb_listener.lb_listener_https.arn
  action {
    type = "redirect"
    redirect {
      host        = "portal.equip.service.justice.gov.uk"
      status_code = "HTTP_301"
    }
  }
  condition {
    host_header {
      values = ["equip-portal.rocstac.com"]
    }
  }
}