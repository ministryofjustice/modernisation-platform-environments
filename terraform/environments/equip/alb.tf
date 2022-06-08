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
  subnets            = [data.aws_subnet.public_subnet_a.id, data.aws_subnet.public_subnet_b.id]

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

resource "aws_lb_target_group" "lb_tg_https" {
  name        = format("tg-%s-%s-443", local.application_name, local.environment)
  target_type = "ip"
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.shared.id
  port        = "443"

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTPS"
    port                = 80
    timeout             = 10
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = local.tags
}

resource "aws_lb_target_group_attachment" "lb_tga_443" {
  target_group_arn = aws_lb_target_group.lb_tg_https.arn
  target_id        = aws_network_interface.adc_vip_interface.private_ip_list[0]
  port             = 443
}

resource "aws_lb_listener" "lb_listener_https" {
  #checkov:skip=CKV_AWS_103
  load_balancer_arn = aws_lb.citrix_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.equip_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.lb_tg_https.arn
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