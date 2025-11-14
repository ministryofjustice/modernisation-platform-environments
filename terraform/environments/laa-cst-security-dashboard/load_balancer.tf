resource "aws_security_group" "cst_lb_sc" {
  name        = "load balancer security group"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS for the Global Protect VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["35.176.93.186/32"]
  }

  egress {
    description = "allow all outbound traffic for port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic for port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "cst_lb" {
  name                       = "cst-load-balancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.cst_lb_sc.id, aws_security_group.lb_sc_pingdom.id, aws_security_group.lb_sc_pingdom_2.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.cst_lb_sc, aws_security_group.lb_sc_pingdom, aws_security_group.lb_sc_pingdom_2]
}

resource "aws_lb_target_group" "cst_target_group" {
  name                 = "cst-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    port                = "80"
    unhealthy_threshold = "5"
    matcher             = "200-302"
    timeout             = "10"
  }

}

resource "aws_lb_listener" "cst_lb" {
  depends_on = [
    aws_acm_certificate.external
  ]
  certificate_arn   = local.is-production ? aws_acm_certificate.external.arn : aws_acm_certificate.external.arn
  load_balancer_arn = aws_lb.cst_lb.arn
  port              = local.application_data.accounts[local.environment].server_port_2
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol_2
  ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cst_target_group.arn
  }
}

resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
  resource_arn = aws_lb.cst_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.cst_web_acl.arn
}
