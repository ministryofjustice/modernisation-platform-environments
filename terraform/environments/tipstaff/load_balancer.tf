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

resource "aws_security_group" "tipstaff_lb_sc_pingdom" {
  name        = "load balancer Pingdom security group"
  description = "control Pingdom access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  // Allow all European Pingdom IP addresses
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "5.172.196.188",
      "13.232.220.164",
      "23.22.2.46",
      "23.83.129.219",
      "23.92.127.2",
      "23.106.37.99",
      "23.111.152.74",
      "23.111.159.174",
      "37.252.231.50",
      "43.225.198.122",
      "43.229.84.12",
      "46.20.45.18",
      "46.246.122.10",
      "50.2.185.66",
      "50.16.153.186",
      "52.0.204.16",
      "52.24.42.103",
      "52.48.244.35",
      "52.52.34.158",
      "52.52.95.213",
      "52.52.118.192",
      "52.57.132.90",
      "52.59.46.112",
      "52.59.147.246",
      "52.62.12.49",
      "52.63.142.2",
      "52.63.164.147",
      "52.63.167.55",
      "52.67.148.55",
      "52.73.209.122",
      "52.89.43.70",
      "52.194.115.181",
      "52.197.31.124",
      "52.197.224.235",
      "52.198.25.184",
      "52.201.3.199",
      "52.209.34.226",
      "52.209.186.226",
      "52.210.232.124",
      "54.68.48.199",
      "54.70.202.58",
      "54.94.206.111",
      "64.237.49.203",
      "64.237.55.3",
      "66.165.229.130",
      "66.165.233.234",
      "72.46.130.18",
      "72.46.131.10",
      "76.72.167.154",
      "76.72.172.208",
      "76.164.234.106",
      "76.164.234.130",
      "82.103.136.16",
      "82.103.139.165",
      "82.103.145.126",
      "85.195.116.134",
      "89.163.146.247",
      "89.163.242.206",
      "94.75.211.73",
      "94.75.211.74",
      "94.247.174.83",
      "96.47.225.18",
      "103.10.197.10",
      "103.47.211.210",
      "104.129.24.154",
      "104.129.30.18",
      "107.182.234.77",
      "108.181.70.3",
      "148.72.170.233",
      "148.72.171.17",
      "151.106.52.134",
      "159.122.168.9",
      "162.208.48.94",
      "162.218.67.34",
      "162.253.128.178",
      "168.1.203.46",
      "169.51.2.18",
      "169.54.70.214",
      "169.56.174.151",
      "172.241.112.86",
      "173.248.147.18",
      "173.254.206.242",
      "174.34.156.130",
      "175.45.132.20",
      "178.162.206.244",
      "178.255.152.2",
      "178.255.153.2",
      "179.50.12.212",
      "184.75.208.210",
      "184.75.209.18",
      "184.75.210.90",
      "184.75.210.226",
      "184.75.214.66",
      "184.75.214.98",
      "185.39.146.214",
      "185.39.146.215",
      "185.70.76.23",
      "185.93.3.65",
      "185.136.156.82",
      "185.152.65.167",
      "185.180.12.65",
      "185.246.208.82",
      "188.172.252.34",
      "190.120.230.7",
      "196.240.207.18",
      "196.244.191.18",
      "196.245.151.42",
      "199.87.228.66",
      "200.58.101.248",
      "201.33.21.5",
      "207.244.80.239",
      "209.58.139.193",
      "209.58.139.194",
      "209.95.50.14",
      "212.78.83.12",
      "212.78.83.16"
    ]
  }
}

resource "aws_lb" "tipstaff_lb" {
  name                       = "tipstaff-load-balancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.tipstaff_lb_sc.id, aws_security_group.tipstaff_lb_sc_pingdom.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.tipstaff_lb_sc, aws_security_group.tipstaff_lb_sc_pingdom]
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
    interval            = "30"
    protocol            = "HTTP"
    port                = "80"
    unhealthy_threshold = "5"
    matcher             = "200-302"
    timeout             = "10"
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

resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
  resource_arn = aws_lb.tipstaff_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.tipstaff_web_acl.arn
}
