resource "aws_security_group" "tipstaff_dev_lb_sc" {
  name        = "load balancer security group"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description       = "allow access for http"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = [local.application_data.accounts[local.environment].moj_ip]
  }

  ingress {
    description       = "allow access for https"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = [local.application_data.accounts[local.environment].moj_ip]
  }

  egress {
    description       = "allow all outbound traffic for port 80"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  egress {
    description       = "allow all outbound traffic for port 443"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "tipstaff_dev_lb" {
  name                       = "tipstaff-dev-load-balancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.tipstaff_dev_lb_sc.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.tipstaff_dev_lb_sc]
}

resource "aws_lb_target_group" "blue" {
  name                 = "tipstaff-dev-target-group"
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
    interval            = "120"
    protocol            = "HTTP"
    port                = "80"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

}

resource "aws_lb_listener" "tipstaff_dev_lb_1" {
  load_balancer_arn = aws_lb.tipstaff_dev_lb.arn
  port              = local.application_data.accounts[local.environment].server_port_1
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol_1
  ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_1 == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

resource "aws_lb_listener" "tipstaff_dev_lb_2" {
  depends_on = [
    aws_acm_certificate.external
  ]
  certificate_arn   = aws_acm_certificate.external.arn
  load_balancer_arn = aws_lb.tipstaff_dev_lb.arn
  port              = local.application_data.accounts[local.environment].server_port_2
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol_2
  ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

resource "aws_lb_target_group" "green" {
  name                 = "tipstaff-dev-target-group_green"
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
    interval            = "120"
    protocol            = "HTTP"
    port                = "80"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

}
