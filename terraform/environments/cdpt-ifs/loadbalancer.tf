resource "aws_security_group" "ifs_lb_sc" {
  name        = "load balancer security group"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["18.169.147.172/32", "35.176.93.186/32", "18.130.148.126/32", "35.176.148.126/32"]
  }

  egress {
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "ifs_lb" {
  name               = "ifs-load-balancer"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ifs_lb_sc.id]
  subnets            = data.aws_subnets.shared-public.ids
  drop_invalid_header_fields = false
}

resource "aws_lb_target_group" "ifs_target_group" {
  name                 = "ifs-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "2"
    interval            = "30"
    unhealthy_threshold = "5"
    matcher             = "200-499"
    timeout             = "10"
  }
}

resource "aws_lb_listener" "https_listener" {
  #checkov:skip=CKV_AWS_103
  depends_on = [aws_acm_certificate_validation.external]

  load_balancer_arn = aws_lb.ifs_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    target_group_arn = aws_lb_target_group.ifs_target_group.id
    type             = "forward"
  }
}
