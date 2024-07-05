resource "aws_alb" "nextcloud" {
  name               = "nextcloud"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nextcloud_alb_sg.id]
  subnets            = var.account_config.public_subnet_ids
  tags               = var.tags
}

resource "aws_alb_listener" "nextcloud_https" {
  load_balancer_arn = aws_alb.nextcloud.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.nextcloud_external.arn

  default_action {
    type             = "forward"
    target_group_arn = module.nextcloud_service.target_group_arn
  }
}

resource "aws_vpc_security_group_ingress_rule" "ancillary_alb_ingress_https_global_protect_allowlist" {
  for_each          = toset(local.all_ingress_ips)
  security_group_id = aws_security_group.nextcloud_alb_sg.id
  description       = "Access into alb over https"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  cidr_ipv4         = each.key # Global Protect VPN
}
