locals {
  lb_name     = "${var.env_name}-dfi-alb"
  lb_endpoint = "ndl_dfi"
}

# Application Load Balancer (modern replacement for Classic ELB)
resource "aws_lb" "dfi" {
  count              = var.lb_config != null ? 1 : 0
  name               = local.lb_name
  load_balancer_type = "application"
  subnets            = var.account_config.public_subnet_ids
  internal           = false
  security_groups    = [aws_security_group.mis_ec2_shared.id]

  enable_cross_zone_load_balancing = true
  idle_timeout                     = 300
  enable_deletion_protection       = false

  access_logs {
    bucket  = module.s3_lb_logs_bucket[0].bucket.id
    prefix  = local.lb_name
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.lb_name)
    },
  )
}

# Target Group for DFI instances
resource "aws_lb_target_group" "dfi" {
  count    = var.lb_config != null ? 1 : 0
  name     = "${local.lb_name}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.account_config.shared_vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/DataServices/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400 # 1 day (same as typical ELB cookie stickiness)
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.lb_name}-tg"
    },
  )
}

# HTTP Listener (port 80)
resource "aws_lb_listener" "dfi_http" {
  count             = var.lb_config != null ? 1 : 0
  load_balancer_arn = aws_lb.dfi[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dfi[0].arn
  }

  tags = local.tags
}

# HTTPS Listener (port 443) - using validated certificate
resource "aws_lb_listener" "dfi_https" {
  count             = var.lb_config != null ? 1 : 0
  load_balancer_arn = aws_lb.dfi[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.dfi_cert_validation[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dfi[0].arn
  }

  tags = local.tags
}

# Self-signed certificate for HTTPS (temporary solution)
# Note: Replace this with a proper ACM certificate in production
resource "aws_acm_certificate" "dfi_self_signed" {
  count             = var.lb_config != null ? 1 : 0
  domain_name       = "${local.lb_endpoint}.${var.env_name}.${var.account_config.dns_suffix}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.lb_name}-cert"
    },
  )
}

# DNS validation records for the certificate
resource "aws_route53_record" "dfi_cert_validation" {
  provider = aws.core-vpc

  for_each = var.lb_config != null ? {
    for dvo in aws_acm_certificate.dfi_self_signed[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.account_config.route53_external_zone.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "dfi_cert_validation" {
  count           = var.lb_config != null ? 1 : 0
  certificate_arn = aws_acm_certificate.dfi_self_signed[0].arn
  validation_record_fqdns = [
    for record in aws_route53_record.dfi_cert_validation : record.fqdn
  ]

  timeouts {
    create = "5m"
  }
}

# Attach DFI instances to the target group
resource "aws_lb_target_group_attachment" "dfi_attachment" {
  count            = var.lb_config != null && var.dfi_config != null ? var.dfi_config.instance_count : 0
  target_group_arn = aws_lb_target_group.dfi[0].arn
  target_id        = module.dfi_instance[count.index].aws_instance.id
  port             = 8080
}

# Create route53 entry for lb
resource "aws_route53_record" "dfi_entry" {
  count    = var.lb_config != null ? 1 : 0
  provider = aws.core-vpc

  zone_id = var.account_config.route53_external_zone.zone_id
  name    = "${local.lb_endpoint}.${var.env_name}.${var.account_config.dns_suffix}"
  type    = "A"

  alias {
    name                   = aws_lb.dfi[0].dns_name
    zone_id                = aws_lb.dfi[0].zone_id
    evaluate_target_health = false
  }
}
