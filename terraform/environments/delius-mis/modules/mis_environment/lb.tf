locals {
  lb_name = "${var.env_name}-mis-alb"

  # DFI endpoint configuration - uses values from dfi_config if available, otherwise defaults
  dfi_enabled  = var.lb_config != null && var.dfi_config != null && var.dfi_config.instance_count > 0
  dfi_endpoint = local.dfi_enabled && try(var.dfi_config.lb_target_config.endpoint, null) != null ? var.dfi_config.lb_target_config.endpoint : "ndl-dfi"
  dfi_fqdn     = "${local.dfi_endpoint}.${var.env_name}.${var.account_config.dns_suffix}"
  dfi_port     = local.dfi_enabled && try(var.dfi_config.lb_target_config.port, null) != null ? var.dfi_config.lb_target_config.port : 8080
  dfi_health_check_path    = local.dfi_enabled && try(var.dfi_config.lb_target_config.health_check_path, null) != null ? var.dfi_config.lb_target_config.health_check_path : "/DataServices/"
  dfi_health_check_matcher = local.dfi_enabled && try(var.dfi_config.lb_target_config.health_check_matcher, null) != null ? var.dfi_config.lb_target_config.health_check_matcher : "200,302,301"

  # DIS endpoint configuration - uses values from dis_config if available, otherwise defaults
  dis_enabled  = var.lb_config != null && var.dis_config != null && var.dis_config.instance_count > 0
  dis_endpoint = local.dis_enabled && try(var.dis_config.lb_target_config.endpoint, null) != null ? var.dis_config.lb_target_config.endpoint : "ndl-dis"
  dis_fqdn     = "${local.dis_endpoint}.${var.env_name}.${var.account_config.dns_suffix}"
  dis_port     = local.dis_enabled && try(var.dis_config.lb_target_config.port, null) != null ? var.dis_config.lb_target_config.port : 8080
  dis_health_check_path    = local.dis_enabled && try(var.dis_config.lb_target_config.health_check_path, null) != null ? var.dis_config.lb_target_config.health_check_path : "/BOE/CMC/"
  dis_health_check_matcher = local.dis_enabled && try(var.dis_config.lb_target_config.health_check_matcher, null) != null ? var.dis_config.lb_target_config.health_check_matcher : "200,302,301"

  # Build certificate SANs dynamically based on what's enabled
  certificate_sans = compact([
    local.dfi_enabled ? local.dfi_fqdn : "",
    local.dis_enabled ? local.dis_fqdn : ""
  ])

  # Build certificate validation map dynamically
  certificate_validation = merge(
    {
      "modernisation-platform.service.justice.gov.uk" = {
        account   = "core-network-services"
        zone_name = "modernisation-platform.service.justice.gov.uk."
      }
    },
    local.dfi_enabled ? {
      "${local.dfi_fqdn}" = {
        account   = "core-vpc"
        zone_name = var.account_config.route53_external_zone.name
      }
    } : {},
    local.dis_enabled ? {
      "${local.dis_fqdn}" = {
        account   = "core-vpc"
        zone_name = var.account_config.route53_external_zone.name
      }
    } : {}
  )
}

# Security group for ALB - Staff access
resource "aws_security_group" "mis_alb_staff" {
  count       = var.lb_config != null ? 1 : 0
  name        = "${local.lb_name}-staff-sg"
  description = "Security group for MIS ALB - Staff access"
  vpc_id      = var.account_config.shared_vpc_id

  tags = merge(
    local.tags,
    {
      "Name" = "${local.lb_name}-staff-sg"
    },
  )
}

# Security group for ALB - End user access
resource "aws_security_group" "mis_alb_enduser" {
  count       = var.lb_config != null ? 1 : 0
  name        = "${local.lb_name}-enduser-sg"
  description = "Security group for MIS ALB - End user access"
  vpc_id      = var.account_config.shared_vpc_id

  tags = merge(
    local.tags,
    {
      "Name" = "${local.lb_name}-enduser-sg"
    },
  )
}

# Security group for ALB - MOJO access
resource "aws_security_group" "mis_alb_mojo" {
  count       = var.lb_config != null ? 1 : 0
  name        = "${local.lb_name}-mojo-sg"
  description = "Security group for MIS ALB - MOJO access"
  vpc_id      = var.account_config.shared_vpc_id

  tags = merge(
    local.tags,
    {
      "Name" = "${local.lb_name}-mojo-sg"
    },
  )
}

# Security group for ALB - Infrastructure access
resource "aws_security_group" "mis_alb_infrastructure" {
  count       = var.lb_config != null ? 1 : 0
  name        = "${local.lb_name}-infra-sg"
  description = "Security group for MIS ALB - Infrastructure access"
  vpc_id      = var.account_config.shared_vpc_id

  tags = merge(
    local.tags,
    {
      "Name" = "${local.lb_name}-infra-sg"
    },
  )
}

# HTTP rules for staff access
resource "aws_vpc_security_group_ingress_rule" "mis_alb_http_staff" {
  for_each          = var.lb_config != null && length(local.internal_security_group_cidrs_staff) > 0 ? toset(local.internal_security_group_cidrs_staff) : []
  security_group_id = aws_security_group.mis_alb_staff[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "Allow HTTP traffic from staff networks: ${each.value}"

  tags = local.tags
}

# HTTPS rules for staff access
resource "aws_vpc_security_group_ingress_rule" "mis_alb_https_staff" {
  for_each          = var.lb_config != null && length(local.internal_security_group_cidrs_staff) > 0 ? toset(local.internal_security_group_cidrs_staff) : []
  security_group_id = aws_security_group.mis_alb_staff[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "Allow HTTPS traffic from staff networks: ${each.value}"

  tags = local.tags
}

# HTTP rules for end user access
resource "aws_vpc_security_group_ingress_rule" "mis_alb_http_enduser" {
  for_each          = var.lb_config != null && length(local.internal_security_group_cidrs_enduser) > 0 ? toset(local.internal_security_group_cidrs_enduser) : []
  security_group_id = aws_security_group.mis_alb_enduser[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "Allow HTTP traffic from enduser networks: ${each.value}"

  tags = local.tags
}

# HTTPS rules for end user access
resource "aws_vpc_security_group_ingress_rule" "mis_alb_https_enduser" {
  for_each          = var.lb_config != null && length(local.internal_security_group_cidrs_enduser) > 0 ? toset(local.internal_security_group_cidrs_enduser) : []
  security_group_id = aws_security_group.mis_alb_enduser[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "Allow HTTPS traffic from enduser networks: ${each.value}"

  tags = local.tags
}

# HTTP rules for MOJO access
resource "aws_vpc_security_group_ingress_rule" "mis_alb_http_mojo" {
  for_each          = var.lb_config != null && length(local.internal_security_group_cidrs_mojo) > 0 ? toset(local.internal_security_group_cidrs_mojo) : []
  security_group_id = aws_security_group.mis_alb_mojo[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "Allow HTTP traffic from MOJO networks: ${each.value}"

  tags = local.tags
}

# HTTPS rules for MOJO access
resource "aws_vpc_security_group_ingress_rule" "mis_alb_https_mojo" {
  for_each          = var.lb_config != null && length(local.internal_security_group_cidrs_mojo) > 0 ? toset(local.internal_security_group_cidrs_mojo) : []
  security_group_id = aws_security_group.mis_alb_mojo[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "Allow HTTPS traffic from MOJO networks: ${each.value}"

  tags = local.tags
}

# HTTP rules for infrastructure access
resource "aws_vpc_security_group_ingress_rule" "mis_alb_http_infrastructure" {
  for_each          = var.lb_config != null && length(local.internal_security_group_cidrs_infrastructure) > 0 ? toset(local.internal_security_group_cidrs_infrastructure) : []
  security_group_id = aws_security_group.mis_alb_infrastructure[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "Allow HTTP traffic from infrastructure networks: ${each.value}"

  tags = local.tags
}

# HTTPS rules for infrastructure access
resource "aws_vpc_security_group_ingress_rule" "mis_alb_https_infrastructure" {
  for_each          = var.lb_config != null && length(local.internal_security_group_cidrs_infrastructure) > 0 ? toset(local.internal_security_group_cidrs_infrastructure) : []
  security_group_id = aws_security_group.mis_alb_infrastructure[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "Allow HTTPS traffic from infrastructure networks: ${each.value}"

  tags = local.tags
}

# Allow ALB security groups to communicate with backend instances on port 8080
resource "aws_vpc_security_group_egress_rule" "mis_alb_backend_staff" {
  count                        = var.lb_config != null ? 1 : 0
  security_group_id            = aws_security_group.mis_alb_staff[0].id
  referenced_security_group_id = aws_security_group.mis_ec2_shared.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow ALB to communicate with MIS instances"

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "mis_alb_backend_enduser" {
  count                        = var.lb_config != null ? 1 : 0
  security_group_id            = aws_security_group.mis_alb_enduser[0].id
  referenced_security_group_id = aws_security_group.mis_ec2_shared.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow ALB to communicate with MIS instances"

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "mis_alb_backend_mojo" {
  count                        = var.lb_config != null ? 1 : 0
  security_group_id            = aws_security_group.mis_alb_mojo[0].id
  referenced_security_group_id = aws_security_group.mis_ec2_shared.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow ALB to communicate with MIS instances"

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "mis_alb_backend_infrastructure" {
  count                        = var.lb_config != null ? 1 : 0
  security_group_id            = aws_security_group.mis_alb_infrastructure[0].id
  referenced_security_group_id = aws_security_group.mis_ec2_shared.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow ALB to communicate with MIS instances"

  tags = local.tags
}

# Allow EC2 instances to receive traffic from ALB security groups on port 8080
resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb_staff" {
  count                        = var.lb_config != null ? 1 : 0
  security_group_id            = aws_security_group.mis_ec2_shared.id
  referenced_security_group_id = aws_security_group.mis_alb_staff[0].id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow MIS ALB to reach instances on port 8080"

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb_enduser" {
  count                        = var.lb_config != null ? 1 : 0
  security_group_id            = aws_security_group.mis_ec2_shared.id
  referenced_security_group_id = aws_security_group.mis_alb_enduser[0].id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow MIS ALB to reach instances on port 8080"

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb_mojo" {
  count                        = var.lb_config != null ? 1 : 0
  security_group_id            = aws_security_group.mis_ec2_shared.id
  referenced_security_group_id = aws_security_group.mis_alb_mojo[0].id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow MIS ALB to reach instances on port 8080"

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb_infrastructure" {
  count                        = var.lb_config != null ? 1 : 0
  security_group_id            = aws_security_group.mis_ec2_shared.id
  referenced_security_group_id = aws_security_group.mis_alb_infrastructure[0].id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow MIS ALB to reach instances on port 8080"

  tags = local.tags
}

# Application Load Balancer - shared by DFI and DIS services
resource "aws_lb" "mis" {
  count              = var.lb_config != null ? 1 : 0
  name               = local.lb_name
  load_balancer_type = "application"
  subnets            = var.account_config.public_subnet_ids
  internal           = false
  security_groups = compact([
    aws_security_group.mis_alb_staff[0].id,
    aws_security_group.mis_alb_enduser[0].id,
    aws_security_group.mis_alb_mojo[0].id,
    aws_security_group.mis_alb_infrastructure[0].id
  ])

  enable_cross_zone_load_balancing = true
  idle_timeout                     = 300
  enable_deletion_protection       = false

  access_logs {
    bucket  = module.s3_lb_logs_bucket[0].bucket.id
    prefix  = local.lb_name
    enabled = true
  }

  # Explicit dependency to ensure S3 bucket exists first
  depends_on = [
    module.s3_lb_logs_bucket
  ]

  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.lb_name)
    },
  )
}

# Target Group for DFI instances - only created if DFI instances exist
resource "aws_lb_target_group" "dfi" {
  count    = local.dfi_enabled ? 1 : 0
  name     = "${local.lb_name}-dfi-tg"
  port     = local.dfi_port
  protocol = "HTTP"
  vpc_id   = var.account_config.shared_vpc_id

  # Deregistration delay - how long to wait before deregistering targets
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    path                = local.dfi_health_check_path
    matcher             = local.dfi_health_check_matcher
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400 # 1 day
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.lb_name}-dfi-tg"
    },
  )
}

# Target Group for DIS instances - only created if DIS instances exist
resource "aws_lb_target_group" "dis" {
  count    = local.dis_enabled ? 1 : 0
  name     = "${local.lb_name}-dis-tg"
  port     = local.dis_port
  protocol = "HTTP"
  vpc_id   = var.account_config.shared_vpc_id

  # Deregistration delay - how long to wait before deregistering targets
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    path                = local.dis_health_check_path
    matcher             = local.dis_health_check_matcher
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400 # 1 day
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.lb_name}-dis-tg"
    },
  )
}

# HTTP Listener (port 80) - default action forwards to DFI (if exists), otherwise DIS
resource "aws_lb_listener" "mis_http" {
  count             = var.lb_config != null ? 1 : 0
  load_balancer_arn = aws_lb.mis[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = local.dfi_enabled ? aws_lb_target_group.dfi[0].arn : aws_lb_target_group.dis[0].arn
  }

  tags = local.tags
}

# HTTPS Listener (port 443) - default action forwards to DFI (if exists), otherwise DIS
resource "aws_lb_listener" "mis_https" {
  count             = var.lb_config != null ? 1 : 0
  load_balancer_arn = aws_lb.mis[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = module.acm_certificate[0].arn

  default_action {
    type             = "forward"
    target_group_arn = local.dfi_enabled ? aws_lb_target_group.dfi[0].arn : aws_lb_target_group.dis[0].arn
  }

  # Explicit dependency to ensure certificate is fully validated before listener creation
  depends_on = [
    module.acm_certificate
  ]

  tags = local.tags
}

# HTTP Listener Rule for DIS - only created if both DFI and DIS exist (otherwise DIS is the default)
resource "aws_lb_listener_rule" "dis_http" {
  count        = local.dfi_enabled && local.dis_enabled ? 1 : 0
  listener_arn = aws_lb_listener.mis_http[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dis[0].arn
  }

  condition {
    host_header {
      values = [local.dis_fqdn]
    }
  }

  tags = local.tags
}

# HTTPS Listener Rule for DIS - only created if both DFI and DIS exist (otherwise DIS is the default)
resource "aws_lb_listener_rule" "dis_https" {
  count        = local.dfi_enabled && local.dis_enabled ? 1 : 0
  listener_arn = aws_lb_listener.mis_https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dis[0].arn
  }

  condition {
    host_header {
      values = [local.dis_fqdn]
    }
  }

  tags = local.tags
}

# ACM certificate using the modernisation platform pattern - dynamically includes SANs based on enabled services
module "acm_certificate" {
  count  = var.lb_config != null ? 1 : 0
  source = "../../../../modules/acm_certificate"

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  name                    = "${local.lb_name}-cert"
  domain_name             = "modernisation-platform.service.justice.gov.uk"
  subject_alternate_names = local.certificate_sans

  validation = local.certificate_validation

  tags = local.tags
}

# Attach DFI instances to the target group - only if DFI is enabled
resource "aws_lb_target_group_attachment" "dfi_attachment" {
  count            = local.dfi_enabled ? var.dfi_config.instance_count : 0
  target_group_arn = aws_lb_target_group.dfi[0].arn
  target_id        = module.dfi_instance[count.index].aws_instance.id
  port             = local.dfi_port

  # Explicit dependency to ensure instances and target group exist first
  depends_on = [
    aws_lb_target_group.dfi,
    module.dfi_instance
  ]
}

# Attach DIS instances to the target group - only if DIS is enabled
resource "aws_lb_target_group_attachment" "dis_attachment" {
  count            = local.dis_enabled ? var.dis_config.instance_count : 0
  target_group_arn = aws_lb_target_group.dis[0].arn
  target_id        = module.dis_instance[count.index].aws_instance.id
  port             = local.dis_port

  # Explicit dependency to ensure instances and target group exist first
  depends_on = [
    aws_lb_target_group.dis,
    module.dis_instance
  ]
}

# Create route53 entry for DFI - only if DFI is enabled
resource "aws_route53_record" "dfi_entry" {
  count    = local.dfi_enabled ? 1 : 0
  provider = aws.core-vpc

  zone_id = var.account_config.route53_external_zone.zone_id
  name    = local.dfi_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.mis[0].dns_name
    zone_id                = aws_lb.mis[0].zone_id
    evaluate_target_health = false
  }
}

# Create route53 entry for DIS - only if DIS is enabled
resource "aws_route53_record" "dis_entry" {
  count    = local.dis_enabled ? 1 : 0
  provider = aws.core-vpc

  zone_id = var.account_config.route53_external_zone.zone_id
  name    = local.dis_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.mis[0].dns_name
    zone_id                = aws_lb.mis[0].zone_id
    evaluate_target_health = false
  }
}
