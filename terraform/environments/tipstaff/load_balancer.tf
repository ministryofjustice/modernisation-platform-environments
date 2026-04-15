resource "aws_security_group" "tipstaff_lb_sc" {
  name        = "load balancer security group"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS for the Dom1 Cisco VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["194.33.192.1/32"]
  }

  ingress {
    description = "allow access on HTTPS for the Global Protect VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["35.176.93.186/32"]
  }

  // Allow user IP addresses
  ingress {
    description = "allow access on HTTPS for user IP addresses"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
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
      "178.248.34.42/32",
      "18.169.147.172/32",
      "18.130.148.126/32",
      "35.176.148.126/32"
    ]
  }

  ingress {
    description = "Replacement DOM1 allow list from Jaz Chan 11/6/24"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "20.26.11.71/32",
      "20.26.11.108/32",
      "20.49.214.199/32",
      "20.49.214.228/32",
      "51.149.249.0/29",
      "51.149.249.32/29",
      "51.149.250.0/24",
      "128.77.75.64/26",
      "194.33.200.0/21",
      "194.33.216.0/23",
      "194.33.218.0/24",
      "194.33.248.0/29",
      "194.33.249.0/29"
    ]
  }

  ingress {
    description = "Allowed IP addresses provided by the users"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
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

  ingress {
    description = "allow all European Pingdom IP addresses"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "94.75.211.73/32",
      "94.75.211.74/32",
      "94.247.174.83/32",
      "96.47.225.18/32",
      "103.10.197.10/32",
      "103.47.211.210/32",
      "104.129.24.154/32",
      "104.129.30.18/32",
      "107.182.234.77/32",
      "108.181.70.3/32",
      "148.72.170.233/32",
      "148.72.171.17/32",
      "151.106.52.134/32",
      "159.122.168.9/32",
      "162.208.48.94/32",
      "162.218.67.34/32",
      "162.253.128.178/32",
      "168.1.203.46/32",
      "169.51.2.18/32",
      "169.54.70.214/32",
      "169.56.174.151/32",
      "172.241.112.86/32",
      "173.248.147.18/32",
      "173.254.206.242/32",
      "174.34.156.130/32",
      "175.45.132.20/32",
      "178.162.206.244/32",
      "178.255.152.2/32",
      "178.255.153.2/32",
      "179.50.12.212/32",
      "184.75.208.210/32",
      "184.75.209.18/32",
      "184.75.210.90/32",
      "184.75.210.226/32",
      "184.75.214.66/32",
      "184.75.214.98/32",
      "185.39.146.214/32",
      "185.39.146.215/32",
      "185.70.76.23/32",
      "185.93.3.65/32",
      "185.136.156.82/32",
      "185.152.65.167/32",
      "185.180.12.65/32",
      "185.246.208.82/32",
      "188.172.252.34/32",
      "190.120.230.7/32",
      "196.240.207.18/32",
      "196.244.191.18/32",
      "196.245.151.42/32",
      "199.87.228.66/32",
      "200.58.101.248/32",
      "201.33.21.5/32",
      "207.244.80.239/32",
      "209.58.139.193/32",
      "209.58.139.194/32",
      "209.95.50.14/32",
      "212.78.83.12/32",
      "212.78.83.16/32"
    ]
  }
}

resource "aws_security_group" "tipstaff_lb_sc_pingdom_2" {
  name        = "load balancer Pingdom security group 2"
  description = "control Pingdom access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow all European Pingdom IP addresses - group 2"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "5.172.196.188/32",
      "13.232.220.164/32",
      "23.22.2.46/32",
      "23.83.129.219/32",
      "23.92.127.2/32",
      "23.106.37.99/32",
      "23.111.152.74/32",
      "23.111.159.174/32",
      "37.252.231.50/32",
      "43.225.198.122/32",
      "43.229.84.12/32",
      "46.20.45.18/32",
      "46.246.122.10/32",
      "50.2.185.66/32",
      "50.16.153.186/32",
      "52.0.204.16/32",
      "52.24.42.103/32",
      "52.48.244.35/32",
      "52.52.34.158/32",
      "52.52.95.213/32",
      "52.52.118.192/32",
      "52.57.132.90/32",
      "52.59.46.112/32",
      "52.59.147.246/32",
      "52.62.12.49/32",
      "52.63.142.2/32",
      "52.63.164.147/32",
      "52.63.167.55/32",
      "52.67.148.55/32",
      "52.73.209.122/32",
      "52.89.43.70/32",
      "52.194.115.181/32",
      "52.197.31.124/32",
      "52.197.224.235/32",
      "52.198.25.184/32",
      "52.201.3.199/32",
      "52.209.34.226/32",
      "52.209.186.226/32",
      "52.210.232.124/32",
      "54.68.48.199/32",
      "54.70.202.58/32",
      "54.94.206.111/32",
      "64.237.49.203/32",
      "64.237.55.3/32",
      "66.165.229.130/32",
      "66.165.233.234/32",
      "72.46.130.18/32",
      "72.46.131.10/32",
      "76.72.167.154/32",
      "76.72.172.208/32",
      "76.164.234.106/32",
      "76.164.234.130/32",
      "82.103.136.16/32",
      "82.103.139.165/32",
      "82.103.145.126/32",
      "85.195.116.134/32",
      "89.163.146.247/32",
      "89.163.242.206/32",
    ]
  }
}

#trivy:ignore:AVD-AWS-0053: this needs to be public
resource "aws_lb" "tipstaff_lb" {
  #checkov:skip=CKV_AWS_91: "ELB Logging not required"
  #checkov:skip=CKV_AWS_150: "Ensure that Load Balancer has deletion protection enabled"
  #checkov:skip=CKV2_AWS_76: "WAFv2 WebACL already associated via aws_wafv2_web_acl_association"
  name                       = "tipstaff-load-balancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.tipstaff_lb_sc.id, aws_security_group.tipstaff_lb_sc_pingdom.id, aws_security_group.tipstaff_lb_sc_pingdom_2.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
  drop_invalid_header_fields = true
  depends_on                 = [aws_security_group.tipstaff_lb_sc]
}

resource "aws_lb_target_group" "tipstaff_target_group" {
  #checkov:skip=CKV_AWS_261 "Health check clearly defined"
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
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    port                = 80
    unhealthy_threshold = 5
    matcher             = "200-302"
    timeout             = 10
  }

}

resource "aws_lb_listener" "tipstaff_lb" {
  #checkov:skip=CKV_AWS_2: "Ensure ALB protocol is HTTPS" - false alert
  #checkov:skip=CKV_AWS_103: "LB using higher version of TLS" - higher than alert
  depends_on = [
    aws_acm_certificate.external
  ]
  certificate_arn   = aws_acm_certificate.external.arn
  load_balancer_arn = aws_lb.tipstaff_lb.arn
  port              = local.application_data.accounts[local.environment].server_port_2
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol_2
  ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tipstaff_target_group.arn
  }
}

resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
  resource_arn = aws_lb.tipstaff_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.tipstaff_web_acl.arn
}
