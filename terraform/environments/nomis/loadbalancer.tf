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

resource "aws_lb" "internal" {
  #checkov:skip=CKV_AWS_91:skip "Ensure the ELBv2 (Application/Network) has access logging enabled". Logging can be considered when the MP load balancer module is available
  name                       = "lb-internal-${local.application_name}"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.internal_elb.id]
  subnets                    = data.aws_subnets.private.ids
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = merge(
    local.tags,
    {
      Name = "internal-loadbalancer"
    },
  )
}

resource "aws_lb_listener" "internal" {
  load_balancer_arn = module.lb_internal_nomis[0].load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  #checkov:skip=CKV_AWS_103:the application does not support tls 1.2
  #tfsec:ignore:aws-elb-use-secure-tls-policy:the application does not support tls 1.2
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.internal_lb.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener_certificate" "certificate_az" {
  count           = local.environment == "test" ? 1 : 0
  listener_arn    = aws_lb_listener.internal.arn
  certificate_arn = aws_acm_certificate.internal_lb_az[0].arn
}

resource "aws_lb_listener" "internal_http" {
  depends_on = [
    aws_acm_certificate_validation.internal_lb
  ]

  load_balancer_arn = module.lb_internal_nomis[0].load_balancer.arn
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

  zone_id = data.aws_route53_zone.external-environment.zone_id
  name    = "*.${local.application_name}.${data.aws_route53_zone.external-environment.name}"
  type    = "A"

  alias {
    name                   = module.lb_internal_nomis[0].load_balancer.dns_name
    zone_id                = module.lb_internal_nomis[0].load_balancer.zone_id
    evaluate_target_health = true
  }
}

#------------------------------------------------------------------------------
# Certificate
#------------------------------------------------------------------------------

resource "aws_acm_certificate" "internal_lb" {
  domain_name       = data.aws_route53_zone.external.name
  validation_method = "DNS"

  subject_alternative_names = ["*.${local.application_name}.${local.vpc_name}-${local.environment}.${data.aws_route53_zone.external.name}"]

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

resource "aws_route53_record" "internal_lb_validation_sub" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.internal_lb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    } if dvo.domain_name != "modernisation-platform.service.justice.gov.uk"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external-environment.zone_id
}

resource "aws_route53_record" "internal_lb_validation_tld" {
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.internal_lb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    } if dvo.domain_name == "modernisation-platform.service.justice.gov.uk"
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
  validation_record_fqdns = [for record in merge(aws_route53_record.internal_lb_validation_tld, aws_route53_record.internal_lb_validation_sub) : record.fqdn]
  depends_on = [
    aws_route53_record.internal_lb_validation_tld,
    aws_route53_record.internal_lb_validation_sub
  ]
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
  #Raised DSOS-1495 to investigate
  #checkov:skip=CKV2_AWS_38: "Ensure Domain Name System Security Extensions (DNSSEC) signing is enabled for Amazon Route 53 public hosted zones"
  #checkov:skip=CKV2_AWS_39: "Ensure Domain Name System (DNS) query logging is enabled for Amazon Route 53 hosted zones"
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
    name                   = module.lb_internal_nomis[0].load_balancer.dns_name
    zone_id                = module.lb_internal_nomis[0].load_balancer.zone_id
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
    for dvo in(local.environment == "test" ? aws_acm_certificate.internal_lb_az[0].domain_validation_options : []) : dvo.domain_name => {
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

# --- New load balancer ---
module "lb_internal_nomis" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer.git?ref=v2.1.0"
  providers = {
    aws.bucket-replication = aws
  }

  count                      = 1
  account_number             = local.environment_management.account_ids[terraform.workspace]
  application_name           = "int-${local.application_name}"
  enable_deletion_protection = false
  idle_timeout               = "60"
  loadbalancer_egress_rules  = local.lb_internal_nomis_egress_rules
  loadbalancer_ingress_rules = local.lb_internal_nomis_ingress_rules
  public_subnets             = data.aws_subnets.private.ids
  region                     = local.region
  vpc_all                    = "${local.vpc_name}-${local.environment}"
  force_destroy_bucket       = true
  internal_lb                = true
  tags = merge(
    local.tags,
    {
      Name = "internal-loadbalancer"
    },
  )
}

locals {
  lb_internal_nomis_egress_rules = {
    lb_internal_nomis_egress_1 = {
      description     = "Allow all outbound"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
  lb_internal_nomis_ingress_rules = {
    lb_internal_nomis_ingress_1 = {
      description     = "allow 443 inbound from PTTP devices"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = [local.cidrs.mojo_globalprotect_internal]
    }
    lb_internal_nomis_ingress_2 = {
      description     = "allow 443 inbound from Jump Server"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [aws_security_group.jumpserver-windows.id]
      cidr_blocks     = []
    }
    lb_internal_nomis_ingress_3 = {
      description     = "allow 80 inbound from PTTP devices"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = [local.cidrs.mojo_globalprotect_internal]
    }
    lb_internal_nomis_ingress_4 = {
      description     = "allow 80 inbound from Jump Server"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [aws_security_group.jumpserver-windows.id]
      cidr_blocks     = []
    }
  }
}
