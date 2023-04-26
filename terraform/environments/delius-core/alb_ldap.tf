# checkov:skip=CKV_AWS_226
# checkov:skip=CKV2_AWS_28

#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "ldap_external" {
  # checkov:skip=CKV_AWS_91
  # checkov:skip=CKV2_AWS_28

  name               = "${local.application_name}-ldap-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ldap_load_balancer_security_group.id]
  subnets            = data.aws_subnets.shared-public.ids

  enable_deletion_protection = true
  drop_invalid_header_fields = true

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_security_group" "ldap_load_balancer_security_group" {
  name_prefix = "${local.application_name}-ldap-lb-security-group"
  description = "controls access to lb"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol    = "tcp"
    description = "Allow ingress from white listed CIDRs"
    from_port   = 389
    to_port     = 389
    cidr_blocks = ["81.134.202.29/32", ]
  }

  egress {
    protocol    = "tcp"
    description = "Allow egress to ECS instances"
    from_port   = 389
    to_port     = 389
    cidr_blocks = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ldap-lb-security-group"
    }
  )
}

resource "aws_lb_listener" "ldap_listener" {
  load_balancer_arn = aws_lb.ldap_external.id
  port              = 389
  protocol          = "TCP"


  default_action {
    target_group_arn = aws_lb_target_group.ldap_target_group_fargate.id
    type             = "forward"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_lb_target_group" "ldap_target_group_fargate" {
  # checkov:skip=CKV_AWS_261

  name                 = "${local.application_name}-ldap-tg"
  port                 = 389
  protocol             = "TCP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}
