# Build loadbalancer security group
resource "aws_security_group" "example-load-balancer-sg" {
  name        = "example-lb-sg"
  description = "controls access to load balancer"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
  )
 
  }
  resource "aws_security_group_rule" "ingress_traffic_lb" {
  for_each          = local.app_variables.example_ec2_sg_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.example-load-balancer-sg.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = local.cidr_blocks
}
resource "aws_security_group_rule" "egress_traffic_lb" {
  for_each          = local.app_variables.example_ec2_sg_rules
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.example-load-balancer-sg.id
  to_port           = each.value.to_port
  type              = "egress"
  source_security_group_id = aws_security_group.example-load-balancer-sg.id
}

# Build loadbalancer

resource "aws_lb" "external" {
  name                       = "${local.application_name}-loadbalancer"
  load_balancer_type         = "application"
  subnets                    = data.aws_subnets.shared-public.ids
  # enable_deletion_protection = true
  # allow 60*4 seconds before 504 gateway timeout for long-running DB operations
  idle_timeout = 240

  security_groups = [aws_security_group.example-load-balancer-sg.id]

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-loadbalancer"
    }
  )

   depends_on = [aws_security_group.example-ec2-sg]
}
resource "aws_lb_target_group" "target_group" {
  name                 = "${local.application_name}-tg-${local.environment}"
  port                 = local.app_variables.accounts[local.environment].server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    # path                = "/"
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-tg-${local.environment}"
    }
  )
}

resource "aws_lb_target_group_attachment" "develop" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.develop.id
  port             = 80
}

#tfsec:ignore:AWS004
# resource "aws_lb_listener" "listener" {
#   #checkov:skip=CKV_AWS_2
#   #checkov:skip=CKV_AWS_103
#   load_balancer_arn = aws_lb.external.id
#   port              = local.app_variables.accounts[local.environment].server_port
#   protocol          = "HTTP"

#   default_action {
#     target_group_arn = aws_lb_target_group.target_group.id
#     type             = "forward"
#   }
# }

# resource "aws_lb_listener" "https_listener" {
#   #checkov:skip=CKV_AWS_103
# #  depends_on = [aws_acm_certificate_validation.external]

#   load_balancer_arn = aws_lb.external.id
#   port              = "443"
#   protocol          = "HTTPS"
#  # certificate_arn   = local.app_variables.accounts[local.environment].cert_arn

#   default_action {
#     target_group_arn = aws_lb_target_group.target_group.id
#     type             = "forward"
#   }
# }

# resource "aws_security_group" "load_balancer_security_group" {
#   name_prefix = "${local.application_name}-loadbalancer-security-group"
#   description = "controls access to lb"
#   vpc_id      = data.aws_vpc.shared.id

#   ingress {
#     protocol    = "tcp"
#     description = "Open the server port"
#     from_port   = local.app_variables.accounts[local.environment].server_port
#     to_port     = local.app_variables.accounts[local.environment].server_port
#     #tfsec:ignore:AWS008
#     cidr_blocks = ["0.0.0.0/0", ]
#   }

#   ingress {
#     protocol    = "tcp"
#     description = "Open the SSL port"
#     from_port   = 443
#     to_port     = 443
#     #tfsec:ignore:AWS008
#     cidr_blocks = ["0.0.0.0/0", ]
#   }

#   egress {
#     protocol    = "-1"
#     description = "Open all outbound ports"
#     from_port   = 0
#     to_port     = 0
#     #tfsec:ignore:AWS009
#     cidr_blocks = [
#       "0.0.0.0/0",
#     ]
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-loadbalancer-security-group"
#     }
#   )
# }