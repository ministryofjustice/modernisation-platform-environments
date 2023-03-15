# PPUD Internal ALB

resource "aws_lb" "PPUD-internal-ALB" {
  count              = local.is-development == false ? 1 : 0
  name               = local.application_data.accounts[local.environment].PPUD_Internal_ALB
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.PPUD-ALB.id]
  subnets            = [data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_listener" "PPUD-Front-End" {
  count             = local.is-development == false ? 1 : 0
  load_balancer_arn = aws_lb.PPUD-internal-ALB[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.internaltest_cert.arn
  /*
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.PPUD-internal-Target-Group[0].arn
  }

*/
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Hi, I am PPUD Internal ALB"
      status_code  = "200"
    }
  }
}

resource "aws_lb_target_group" "PPUD-internal-Target-Group" {
  count    = local.is-development == false ? 1 : 0
  name     = local.application_data.accounts[local.environment].PPUD_Target
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.shared.id
  stickiness {
    cookie_duration = 86400
    type            = "lb_cookie"
    enabled         = true
  }

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTPS"
    port                = 443
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "302"
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }

}


resource "aws_lb_target_group_attachment" "PPUD-PORTAL-internal-development" {
  count            = local.is-preproduction == true ? 1 : 0
  target_group_arn = aws_lb_target_group.PPUD-internal-Target-Group[0].arn
  target_id        = aws_instance.s618358rgvw023[0].id
  port             = 443
}