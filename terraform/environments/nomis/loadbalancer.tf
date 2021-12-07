#------------------------------------------------------------------------------
# Load Balancer - Internal
#------------------------------------------------------------------------------

data "aws_subnet_ids" "private" {
  vpc_id = local.vpc_id
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}*"
  }
}

resource "aws_security_group" "internal_elb" {

  name        = "internal-lb-${local.application_name}"
  description = "Allow inbound traffic to internal load balancer"
  vpc_id      = local.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "internal-lb-${local.application_name}"
    },
  )
}

resource "aws_security_group_rule" "internal_lb_ingress_1" {

  description       = "all 443 inbound from anywhere (limited by subnet ACL)"
  security_group_id = aws_security_group.internal_elb.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "internal_lb_egress_1" {

  description              = "all outbound to weblogic targets"
  security_group_id        = aws_security_group.internal_elb.id
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.weblogic_server.id
}

resource "aws_lb" "internal" {

  name                       = "lb-internal-${local.application_name}"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.internal_elb.id]
  subnets                    = data.aws_subnet_ids.private.ids
  enable_deletion_protection = false

  tags = merge(
    local.tags,
    {
      Name = "internal-${local.application_name}"
    },
  )
}

resource "aws_lb_target_group" "weblogic" {

  name                 = "weblogic-${local.application_name}"
  port                 = "80" # port on which targets receive traffic
  protocol             = "HTTPS"
  target_type          = "ip"
  deregistration_delay = "30"
  vpc_id               = local.vpc_id

  health_check {
    enabled             = true
    interval            = "30"
    healthy_threshold   = "3"
    matcher             = "200-399"
    path                = "/keepalive.htm"
    port                = "7777"
    timeout             = "5"
    unhealthy_threshold = "5"
  }

  # access_logs { maybe we want this?
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = merge(
    local.tags,
    {
      Name = "weblogic-${local.application_name}"
    },
  )
}

resource "aws_lb_target_group_attachment" "weblogic" {
  target_group_arn = aws_lb_target_group.weblogic.arn
  target_id        = "10.26.8.87"
  port             = "80"
}

resource "aws_lb_listener" "internal" {
  depends_on = [
    aws_acm_certificate_validation.internal_lb
  ]

  load_balancer_arn = aws_lb.internal.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.internal_lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.weblogic.arn
  }
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------
resource "aws_route53_record" "internal_lb" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

#------------------------------------------------------------------------------
# Certificate
#------------------------------------------------------------------------------

resource "aws_acm_certificate" "internal_lb" {
  domain_name       = "${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"]

  tags = merge(
    local.tags,
    {
      Name = "internal-lb-${local.application_name}"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "internal_lb_validation" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.internal_lb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "internal_lb" {
  certificate_arn         = aws_acm_certificate.internal_lb.arn
  validation_record_fqdns = [for record in aws_route53_record.internal_lb_validation : record.fqdn]
}

#------------------------------------------------------------------------------
# Web Application Firewall
#------------------------------------------------------------------------------

# resource "aws_wafv2_web_acl" "waf" {
# #TODO https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl
# }