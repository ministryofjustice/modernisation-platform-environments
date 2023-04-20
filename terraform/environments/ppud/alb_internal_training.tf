#############################
# PPUD Training ALB - Preprod
#############################

resource "aws_lb" "PPUD-Training-ALB" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "PPUD-Training-ALB"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.PPUD-ALB.id]
  subnets            = [data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_listener" "PPUD-Training-Front-End" {
  count             = local.is-preproduction == true ? 1 : 0
  load_balancer_arn = aws_lb.PPUD-Training-ALB[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.internaltest_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.PPUD-Training[0].arn
  }
}

resource "aws_lb_target_group" "PPUD-Training" {
  count    = local.is-preproduction == true ? 1 : 0
  name     = "PPUD-Training"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTP"
    port                = 80
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "302"
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_target_group_attachment" "PPUD-PORTAL-Training" {
  count            = local.is-preproduction == true ? 1 : 0
  target_group_arn = aws_lb_target_group.PPUD-Training[0].arn
  target_id        = aws_instance.s618358rgvw023[0].id
  port             = 80
}