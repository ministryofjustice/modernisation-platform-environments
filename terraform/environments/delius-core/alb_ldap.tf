locals {
  openldap_name     = format("%s-openldap", local.application_name)
  openldap_alb_name = format("%s-alb", local.openldap_name)
  openldap_alb_tags = merge(
    local.tags,
    {
      Name = local.openldap_alb_name
    }
  )

  openldap_protocol = "tcp"
}
resource "aws_lb" "ldap" {
  name                       = local.openldap_alb_name
  internal                   = true
  load_balancer_type         = "network"
  security_groups            = [aws_security_group.ldap_nlb.id]
  subnets                    = data.aws_subnets.shared-private.ids
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  tags = local.openldap_alb_tags
}

resource "aws_security_group" "ldap_nlb" {
  name        = local.openldap_alb_name
  description = "allow inbound traffic from the VPN and within the VPC on port 389"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port = local.openldap_port
    to_port   = local.openldap_port
    protocol  = local.openldap_protocol
    cidr_blocks = [
      data.aws_vpc.shared.cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.openldap_alb_tags
}

resource "aws_lb_listener" "ldap" {
  load_balancer_arn = aws_lb.ldap.arn
  port              = local.openldap_port
  protocol          = local.openldap_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ldap.arn
  }

  tags = local.openldap_alb_tags
}

resource "aws_lb_target_group" "ldap" {
  name     = local.openldap_name
  port     = local.openldap_port
  protocol = local.openldap_protocol
  vpc_id   = data.aws_vpc.shared.id

  target_type          = "ip"
  deregistration_delay = "30"
  tags = merge(
    local.tags,
    {
      Name = local.openldap_name
    }
  )
}
