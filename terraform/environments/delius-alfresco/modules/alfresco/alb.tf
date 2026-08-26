# internal application load balancer
resource "aws_lb" "alfresco_sfs" {
  name               = "${var.app_name}-${var.env_name}-alf-sfs-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alfresco_sfs_alb.id]
  subnets            = var.account_config.private_subnet_ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true
}


resource "aws_lb_listener" "alfresco_sfs_listener_https" {
  load_balancer_arn = aws_lb.alfresco_sfs.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.alf_external.arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }
}

resource "aws_security_group" "alfresco_sfs_alb" {
  name        = "${terraform.workspace}-alf-sfs-alb"
  description = "controls access to and from alfresco sfs load balancer"
  vpc_id      = var.account_config.shared_vpc_id
  tags        = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alfresco_sfs_alb" {
  for_each          = toset([var.account_info.cp_cidr, var.account_config.shared_vpc_cidr])
  security_group_id = aws_security_group.alfresco_sfs_alb.id
  description       = "Access into alb over https"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  cidr_ipv4         = each.key
}

resource "aws_vpc_security_group_egress_rule" "alfresco_sfs_alb" {
  security_group_id = aws_security_group.alfresco_sfs_alb.id
  description       = "egress from alb to ecs cluster"
  ip_protocol       = "-1"
  cidr_ipv4         = var.account_config.shared_vpc_cidr
}