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
      Name = "internal-loadbalancer-sg"
    },
  )
}

resource "aws_security_group_rule" "internal_lb_ingress_1" {

  description       = "allow 443 inbound from PTTP devices"
  security_group_id = aws_security_group.internal_elb.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.184.0.0/16"] # Global Protect PTTP devices
}

resource "aws_security_group_rule" "internal_lb_ingress_2" {

  description              = "allow 443 inbound from Jump Server"
  security_group_id        = aws_security_group.internal_elb.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jumpserver-windows.id
}

resource "aws_security_group_rule" "internal_lb_egress_1" {

  description              = "allow outbound to weblogic targets"
  security_group_id        = aws_security_group.internal_elb.id
  type                     = "egress"
  from_port                = 7777
  to_port                  = 7777
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.weblogic_common.id
}

resource "aws_lb" "internal" {
  #checkov:skip=CKV_AWS_91:skip "Ensure the ELBv2 (Application/Network) has access logging enabled"
  name                       = "lb-internal-${local.application_name}"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.internal_elb.id]
  subnets                    = data.aws_subnet_ids.private.ids
  enable_deletion_protection = true
  drop_invalid_header_fields = true

  tags = merge(
    local.tags,
    {
      Name = "internal-loadbalancer"
    },
  )
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
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "503"
    }
  }
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------
resource "aws_route53_record" "internal_lb" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "*.${data.aws_route53_zone.external.name}"
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
  domain_name       = "${local.application_name}.${data.aws_route53_zone.external.name}"
  validation_method = "DNS"

  subject_alternative_names = ["*.${local.application_name}.${data.aws_route53_zone.external.name}"]

  tags = merge(
    local.tags,
    {
      Name = "internal-lb-cert"
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