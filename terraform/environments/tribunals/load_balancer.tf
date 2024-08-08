locals {
  target_group_arns = { for k, v in aws_lb_target_group.tribunals_target_group : k => v.arn }

  # Create a mapping between listener headers and target group ARNs
  listener_header_to_target_group = {
    for k, v in var.services :
    v.name_prefix => aws_lb_target_group.tribunals_target_group[k].arn
  }
}

resource "aws_lb" "tribunals_lb" {
  name                       = "tribunals-lb"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.tribunals_lb_sc.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
}

resource "aws_security_group" "tribunals_lb_sc" {
  name        = "tribunals-load-balancer-sg"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow all traffic on HTTPS port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow all traffic on HTTP port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic from the load balancer - needed due to dynamic port mapping on ec2 instance"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "tribunals_target_group" {
  for_each             = var.services
  name                 = "${each.value.name_prefix}-tg"
  port                 = each.value.port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "3"
    interval            = "15"
    protocol            = "HTTP"
    unhealthy_threshold = "3"
    matcher             = "200-499"
    timeout             = "10"
  }
}

data "aws_instances" "tribunals_instance" {
  filter {
    name   = "tag:Name"
    values = ["tribunals-instance"]
  }
}

# resource "aws_lb_target_group_attachment" "tribunals_target_group_attachment" {
#   for_each         = aws_lb_target_group.tribunals_target_group
#   target_group_arn = each.value.arn
#   target_id        = element(data.aws_instances.tribunals_instance.ids, 0)
#   port             = each.value.port
# }

resource "aws_lb_listener" "tribunals_lb" {
  depends_on = [
    aws_acm_certificate.external
  ]
  certificate_arn   = aws_acm_certificate.external.arn
  load_balancer_arn = aws_lb.tribunals_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No matching rule found"
      status_code  = "404"
    }
  }
}
resource "aws_lb_listener_rule" "tribunals_lb_rule" {
  for_each = local.listener_header_to_target_group

  listener_arn = aws_lb_listener.tribunals_lb.arn
  priority     = index(keys(local.listener_header_to_target_group), each.key) + 1

  action {
    type             = "forward"
    target_group_arn = each.value
  }

  condition {
    host_header {
      values = ["*${each.key}.*"]
    }
  }
}
