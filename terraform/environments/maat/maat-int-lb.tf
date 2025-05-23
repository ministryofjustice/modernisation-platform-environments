######################################
# Security Group for Internal LB
######################################

resource "aws_security_group" "maat_int_lb_sg" {
  name        = "${local.application_name}-internal-lb-security-group"
  description = "MAAT Internal LB Security Group"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-internal-lb-security-group"
    }
  )
}

resource "aws_security_group_rule" "maat_int_lb_sg_rule_transit_gw" {
  security_group_id = aws_security_group.maat_int_lb_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["172.20.0.0/16"] #The transit gateway cidr would need to replaced without something equivalent when migrated to MP
}

resource "aws_security_group_rule" "internal_lb_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.maat_ecs_security_group.id
  security_group_id        = aws_security_group.maat_int_lb_sg.id
}


######################################
# Internal Load Balancer
######################################

resource "aws_lb" "maat_internal_lb" {
  name               = "${local.application_name}-InternalLoadBalancer"
  load_balancer_type = "application"
  internal           = true
  idle_timeout       = 65
  subnets            = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  security_groups    = [aws_security_group.maat_int_lb_sg.id]

  enable_deletion_protection = true

  #   access_logs {
  #     bucket  = local.existing_bucket_name != "" ? local.existing_bucket_name : module.lb-s3-access-logs[0].bucket.id
  #     prefix  = "${local.application_name}-InternalLoadBalancer"
  #     enabled = true
  #   }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-internal-load-balancer"
    },
  )
}


######################################
# Internal Load Balancer Target Group
######################################

resource "aws_lb_target_group" "maat_internal_lb_target_group" {
  name                 = "${local.application_name}-Int-LB-TG"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  deregistration_delay = 30

  health_check {
    interval            = 15
    path                = "/ccmt-web/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 10800
  }
}


######################################
# Internal Load Balancer Listener
######################################

resource "aws_lb_listener" "maat_internal_lb_https_listener" {

  load_balancer_arn = aws_lb.maat_internal_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.ext_lb_listener_protocol == "HTTPS" ? aws_acm_certificate_validation.load_balancers.certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.maat_internal_lb_target_group.arn
  }
}

resource "aws_lb_listener_rule" "maat_internal_lb_https_listener_rule" {
  listener_arn = aws_lb_listener.maat_internal_lb_https_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.maat_internal_lb_target_group.arn
  }

  condition {
    source_ip {
      values = ["172.20.0.0/16"]
    }
  }
}

#######################################
# Internal Load Balancer Reoute 53
######################################

resource "aws_route53_record" "internal_lb_non_prod" {
  count    = local.environment != "production" ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = local.int_lb_url
  type     = "CNAME"
  ttl      = 300
  records  = [aws_lb.maat_internal_lb.dns_name]
}

resource "aws_route53_record" "internal_lb_prod" {
  count    = local.environment == "production" ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.production-network-services.zone_id # TODO The zone may change as this currently points to the same one that hosted the CloudFront record
  name     = "tbc"                                                     # TODO Production URL to be confirmed
  type     = "CNAME"
  ttl      = 300
  records  = [aws_lb.maat_internal_lb.dns_name]
}

