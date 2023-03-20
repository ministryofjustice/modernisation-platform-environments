# checkov:skip=CKV_AWS_226
# checkov:skip=CKV2_AWS_28

# Create security group and rules for load balancer
resource "aws_security_group" "delius_frontend_alb_security_group" {
  name        = "Delius Core Frontend Load Balancer"
  description = "controls access to and from delius front-end load balancer"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_alb_ingress_allowlist" {
  security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  description       = "access into delius core frontend alb"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  cidr_ipv4         = "81.134.202.29/32" # MoJ Digital VPN
}

resource "aws_vpc_security_group_egress_rule" "delius_core_frontend_alb_egress_frontend_service" {
  security_group_id            = aws_security_group.delius_frontend_alb_security_group.id
  description                  = "access from delius core frontend alb to ecs"
  from_port                    = local.frontend_container_port
  to_port                      = local.frontend_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.delius_core_frontend_security_group.id
  tags                         = local.tags
}

#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "delius_core_frontend" {
  # checkov:skip=CKV_AWS_91
  # checkov:skip=CKV2_AWS_28

  name               = "${local.application_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.delius_frontend_alb_security_group.id]
  subnets            = data.aws_subnets.shared-public.ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true
}

# resource "aws_lb_listener" "listener" {
#   load_balancer_arn = aws_lb.delius_core_frontend.id
#   port              = 443
#   protocol          = "HTTPS"
#   certificate_arn   = aws_acm_certificate.external.arn
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

#   default_action {
#     target_group_arn = aws_lb_target_group.delius_core_frontend_target_group.id
#     type             = "forward"
#   }
# }

resource "aws_lb_target_group" "delius_core_frontend_target_group" {
  # checkov:skip=CKV_AWS_261

  name                 = format("%s-tg", local.frontend_fully_qualified_name)
  port                 = local.frontend_container_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30
  tags                 = local.tags

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    # path                = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }
}

# resource "aws_route53_record" "external" {
#   provider = aws.core-vpc

#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = local.frontend_url
#   type    = "A"

#   alias {
#     name                   = aws_lb.delius_core_frontend.dns_name
#     zone_id                = aws_lb.delius_core_frontend.zone_id
#     evaluate_target_health = true
#   }
# }

resource "aws_acm_certificate" "external" {
  domain_name               = "modernisation-platform.service.justice.gov.uk"
  validation_method         = "DNS"
  subject_alternative_names = [local.frontend_url]
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}
