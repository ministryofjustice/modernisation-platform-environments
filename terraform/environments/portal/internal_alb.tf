locals {
  internal_lb_idle_timeout = 180
  internal_lb_http_port    = 80
  internal_lb_https_port   = 443
  internal_lb_http_hosts   = [aws_route53_record.oim_internal.name, aws_route53_record.oam_internal.name, aws_route53_record.idm_console.name, aws_route53_record.ohs_internal.name]
}

####################################
# Internal Portal ELB to OHS
####################################

resource "aws_lb" "internal" {
  name                       = "${local.application_name}-internal-lb"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.internal_lb.id]
  subnets                    = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  enable_deletion_protection = local.lb_enable_deletion_protection
  idle_timeout               = local.internal_lb_idle_timeout

  access_logs {
    bucket  = local.lb_logs_bucket != "" ? local.lb_logs_bucket : module.elb-logs-s3[0].bucket.id
    prefix  = "${local.application_name}-internal-lb"
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-internal-lb"
    },
  )
}

resource "aws_lb_listener" "http_internal" {

  load_balancer_arn = aws_lb.internal.arn
  port              = local.internal_lb_http_port
  protocol          = "HTTP"

  # TODO This needs using once Cert and CloudFront has been set up
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }

  tags = local.tags

}

# TODO This needs uncommenting once Cert has been set up
resource "aws_lb_listener" "https_internal" {

  load_balancer_arn = aws_lb.internal.arn
  port              = local.internal_lb_https_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.load_balancer.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal.arn
  }

  tags = local.tags

}

resource "aws_lb_listener_rule" "host_based_internal" {
  listener_arn = aws_lb_listener.http_internal.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal.arn
  }

  condition {
    host_header {
      values = local.internal_lb_http_hosts # These are the URLs that accessed the LAA-Porta-AppOhsIn CLB in Landing Zone via Port 80, but we have merged this CLB with the Internal ALB instead, so this additional rule is required
    }
  }

}

# TODO This needs uncommenting once Cert has been set up
resource "aws_lb_listener_rule" "https_internal" {
  listener_arn = aws_lb_listener.https_internal.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }

}

resource "aws_lb_target_group" "internal" {
  name                 = "${local.application_name}-internal-ohs-target-group"
  port                 = 7777
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  deregistration_delay = 30
  # load_balancing_algorithm_type = "least_outstanding_requests"
  health_check {
    interval            = 5
    path                = "/"
    protocol            = "HTTP"
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = 302
  }
  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 10800
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-internal-ohs-target-group"
    },
  )

}

resource "aws_lb_target_group_attachment" "ohs1_internal" {
  target_group_arn = aws_lb_target_group.internal.arn
  target_id        = aws_instance.ohs_instance_1.id
  port             = 7777
}

resource "aws_lb_target_group_attachment" "ohs2_internal" {
  count            = contains(["development", "testing"], local.environment) ? 0 : 1
  target_group_arn = aws_lb_target_group.internal.arn
  target_id        = aws_instance.ohs_instance_2[0].id
  port             = 7777
}


############################################
# internal Portal ELB Security Group
############################################

resource "aws_security_group" "internal_lb" {
  name        = "${local.application_name}-internal-lb-security-group"
  description = "${local.application_name} internal alb security group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "internal_lb_vpc" {
  security_group_id = aws_security_group.internal_lb.id
  description       = "From account VPC"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port         = local.internal_lb_http_port
  ip_protocol       = "tcp"
  to_port           = local.internal_lb_http_port
}

resource "aws_vpc_security_group_ingress_rule" "internal_lb_vpc_https" {
  security_group_id = aws_security_group.internal_lb.id
  description       = "From account VPC"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port         = local.internal_lb_https_port
  ip_protocol       = "tcp"
  to_port           = local.internal_lb_https_port
}

resource "aws_vpc_security_group_ingress_rule" "internal_lb_https_np_workspaces" {
  count             = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.internal_lb.id
  description       = "HTTPS access for non-prod London Workspaces"
  cidr_ipv4         = local.nonprod_workspaces_cidr
  from_port         = local.internal_lb_https_port
  ip_protocol       = "tcp"
  to_port           = local.internal_lb_https_port
}

resource "aws_vpc_security_group_ingress_rule" "internal_lb_http_np_workspaces" {
  count             = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.internal_lb.id
  description       = "HTTP access for non-prod London Workspaces"
  cidr_ipv4         = local.nonprod_workspaces_cidr
  from_port         = local.internal_lb_http_port
  ip_protocol       = "tcp"
  to_port           = local.internal_lb_http_port
}


resource "aws_vpc_security_group_ingress_rule" "internal_lb_https_prd_workspaces" {
  count             = contains(["development", "testing"], local.environment) ? 0 : 1
  security_group_id = aws_security_group.internal_lb.id
  description       = "HTPS access for prod London Workspaces"
  cidr_ipv4         = local.prod_workspaces_cidr
  from_port         = local.internal_lb_https_port
  ip_protocol       = "tcp"
  to_port           = local.internal_lb_https_port
}

resource "aws_vpc_security_group_ingress_rule" "internal_lb_http_prd_workspaces" {
  count             = contains(["development", "testing"], local.environment) ? 0 : 1
  security_group_id = aws_security_group.internal_lb.id
  description       = "HTTP access for prod London Workspaces"
  cidr_ipv4         = local.prod_workspaces_cidr
  from_port         = local.internal_lb_http_port
  ip_protocol       = "tcp"
  to_port           = local.internal_lb_http_port
}


resource "aws_vpc_security_group_egress_rule" "internal_lb_outbound" {
  security_group_id = aws_security_group.internal_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
