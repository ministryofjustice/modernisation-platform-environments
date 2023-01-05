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

# --- New load balancer ---
module "lb_internal_nomis" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer.git?ref=v2.1.0"
  count  = 0
  providers = {
    aws.bucket-replication = aws
  }

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
