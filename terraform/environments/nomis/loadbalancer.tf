#------------------------------------------------------------------------------
# Load Balancer - Internal
#------------------------------------------------------------------------------
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
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

resource "aws_security_group_rule" "internal_lb_ingress_3" {

  description       = "allow 80 inbound from PTTP devices"
  security_group_id = aws_security_group.internal_elb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.184.0.0/16"] # Global Protect PTTP devices
}

resource "aws_security_group_rule" "internal_lb_ingress_4" {

  description              = "allow 80 inbound from Jump Server"
  security_group_id        = aws_security_group.internal_elb.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
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
  subnets                    = data.aws_subnets.private.ids
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
    # aws_acm_certificate_validation.internal_lb
    aws_acm_certificate_validation.internal_lb_az
  ]

  load_balancer_arn = aws_lb.internal.arn
  port              = "443"
  protocol          = "HTTPS"
  #checkov:skip=CKV_AWS_103:the application does not support tls 1.2
  #tfsec:ignore:aws-elb-use-secure-tls-policy:the application does not support tls 1.2
  ssl_policy = "ELBSecurityPolicy-2016-08"
  # certificate_arn = aws_acm_certificate.internal_lb.arn # this is what we'll use once we go back to modplatform dns
  certificate_arn = local.environment == "test" ? aws_acm_certificate.internal_lb_az[0].arn : aws_acm_certificate.internal_lb.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener" "internal_http" {
  depends_on = [
    aws_acm_certificate_validation.internal_lb
  ]

  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------
resource "aws_route53_record" "internal_lb" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "*.${local.application_name}.${data.aws_route53_zone.external.name}"
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


#------------------------------------------------------------------------------
# Temporaray resources to support access from PTTP
# Note will also need to revert the following when this is retired:
# 1. route 53 external zone datasource in the weblogic module
# 2. Loadbalancer listener rule host header in weblogic module
# 3. aws_lb_listener.internal.certificate_arn in this file
# Hopefully this will be gone by the time we need to create weblogics in prod
# if not then additional work will be required in the weblogic module
#------------------------------------------------------------------------------

resource "aws_route53_zone" "az" {
  count = local.environment == "test" ? 1 : 0
  name  = "modernisation-platform.nomis.az.justice.gov.uk"
  tags = merge(
    local.tags,
    {
      Name = "modernisation-platform.nomis.az.justice.gov.uk"
    }
  )
}

resource "aws_route53_record" "internal_lb_az" {
  count   = local.environment == "test" ? 1 : 0
  zone_id = aws_route53_zone.az[0].zone_id
  name    = "*.${aws_route53_zone.az[0].name}"
  type    = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "internal_lb_az" {
  count             = local.environment == "test" ? 1 : 0
  domain_name       = aws_route53_zone.az[0].name
  validation_method = "DNS"

  subject_alternative_names = ["*.${aws_route53_zone.az[0].name}"]

  tags = merge(
    local.tags,
    {
      Name = "internal-lb-cert-az"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "internal_lb_validation_az" {
  for_each = {
    for dvo in aws_acm_certificate.internal_lb_az[0].domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.az[0].zone_id
}

resource "aws_acm_certificate_validation" "internal_lb_az" {
  count                   = local.environment == "test" ? 1 : 0
  certificate_arn         = aws_acm_certificate.internal_lb_az[0].arn
  validation_record_fqdns = [for record in aws_route53_record.internal_lb_validation_az : record.fqdn]
}