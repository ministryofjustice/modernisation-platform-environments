resource "aws_security_group" "tipstaff_lb_sc" {
  name        = "load balancer security group"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS for the MOJ VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].moj_ip]
  }

  // Allow all IP addresses that had load balancer access in the Tactical Products environment
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "178.248.34.44/32",
      "194.33.192.0/25",
      "195.59.75.0/24",
      "178.248.34.45/32",
      "201.33.21.5/32",
      "178.248.34.46/32",
      "188.172.252.34/32",
      "178.248.34.43/32",
      "92.177.120.49/32",
      "157.203.176.0/25",
      "179.50.12.212/32",
      "213.121.161.112/28",
      "2.138.20.8/32",
      "93.56.171.15/32",
      "213.121.161.124/32",
      "52.67.148.55/32",
      "194.33.196.0/25",
      "194.33.197.0/25",
      "79.152.189.104/32",
      "89.32.121.144/32",
      "178.248.34.47/32",
      "185.191.249.100/32",
      "54.94.206.111/32",
      "194.33.193.0/25",
      "178.248.34.42/32"
    ]
  }

  // Allow all IP addresses provided by the users
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "194.33.196.47/32",
      "194.33.192.6/32",
      "194.33.192.47/32",
      "194.33.192.6/32",
      "194.33.192.2/32",
      "194.33.196.46/32",
      "194.33.192.5/32"
    ]
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

resource "aws_lb" "tipstaff_lb" {
  name                       = "tipstaff-load-balancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.tipstaff_lb_sc.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.tipstaff_lb_sc]
}

resource "aws_lb_target_group" "tipstaff_target_group" {
  name                 = "tipstaff-target-group"
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
    interval            = "15"
    protocol            = "HTTP"
    port                = "80"
    unhealthy_threshold = "3"
    matcher             = "200-302"
    timeout             = "5"
  }

}

resource "aws_lb_listener" "tipstaff_lb" {
  depends_on = [
    aws_acm_certificate.external
  ]
  certificate_arn   = local.is-production ? aws_acm_certificate.external_prod[0].arn : aws_acm_certificate.external.arn
  load_balancer_arn = aws_lb.tipstaff_lb.arn
  port              = local.application_data.accounts[local.environment].server_port_2
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol_2
  ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tipstaff_target_group.arn
  }
}
