locals {
  lb_name     = "${var.env_name}-dfi-alb"
  lb_endpoint = "ndl_dfi"
  # Use original ndl_dfi endpoint
  lb_fqdn     = "${local.lb_endpoint}.${var.env_name}.${var.account_config.dns_suffix}"
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

# HTTPS Listener (port 443) - using ACM module certificate
resource "aws_lb_listener" "dfi_https" {
  count             = var.lb_config != null ? 1 : 0
  load_balancer_arn = aws_lb.dfi[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = module.acm_certificate[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dfi[0].arn
  }

  # Explicit dependency to ensure certificate is fully validated before listener creation
  depends_on = [
    module.acm_certificate
  ]

  tags = local.tags
}

# ACM certificate using the modernisation platform pattern
module "acm_certificate" {
  count  = var.lb_config != null ? 1 : 0
  source = "../../../../modules/acm_certificate"

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  name                    = "${local.lb_name}-cert"
  domain_name             = "modernisation-platform.service.justice.gov.uk"
  subject_alternate_names = [local.lb_fqdn]
  
  validation = {
    "modernisation-platform.service.justice.gov.uk" = {
      account   = "core-network-services"
      zone_name = "modernisation-platform.service.justice.gov.uk."
    }
    "${local.lb_fqdn}" = {
      account   = "core-vpc"
      zone_name = var.account_config.route53_external_zone.name
    }
  }

  tags = local.tags
}

# Attach DFI instances to the target group
resource "aws_lb_target_group_attachment" "dfi_attachment" {
  count            = var.lb_config != null && var.dfi_config != null ? var.dfi_config.instance_count : 0
  target_group_arn = aws_lb_target_group.dfi[0].arn
  target_id        = module.dfi_instance[count.index].aws_instance.id
  port             = 8080

  # Explicit dependency to ensure instances and target group exist first
  depends_on = [
    aws_lb_target_group.dfi,
    module.dfi_instance
  ]
}

# Create route53 entry for ALB
resource "aws_route53_record" "dfi_entry" {
  count    = var.lb_config != null ? 1 : 0
  provider = aws.core-vpc

  zone_id = var.account_config.route53_external_zone.zone_id
  name    = local.lb_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.dfi[0].dns_name
    zone_id                = aws_lb.dfi[0].zone_id
    evaluate_target_health = false
  }
}
