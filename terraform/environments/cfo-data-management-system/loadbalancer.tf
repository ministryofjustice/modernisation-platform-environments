# MP Load Balancer Module - https://github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer

# API Load Balancer
module "lb_api" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=v5.2.0"
  providers = {
    aws.bucket-replication = aws
  }

  vpc_all                    = "${local.vpc_name}-${local.environment}"
  force_destroy_bucket       = !local.is-production
  application_name           = "${local.application_name_short}-api"
  public_subnets             = data.aws_subnets.shared-public.ids
  loadbalancer_ingress_rules = local.api_lb_ingress_rules
  loadbalancer_egress_rules  = local.api_lb_egress_rules
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = "eu-west-2"
  enable_deletion_protection = local.is-production
  idle_timeout               = 60
  tags                       = local.tags
}

resource "aws_lb_target_group" "api" {
  name_prefix          = "api-"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    path                = "/health"
    port                = "8080"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }

  tags = merge(local.tags, { Name = "${local.application_name_short}-${local.environment}-api" })
}

# API ALB Listener
resource "aws_lb_listener" "api_https" {
  load_balancer_arn = module.lb_api.load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = module.visualiser_cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# Visualiser Load Balancer
module "lb_visualiser" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=v5.2.0"
  providers = {
    aws.bucket-replication = aws
  }

  vpc_all                    = "${local.vpc_name}-${local.environment}"
  force_destroy_bucket       = !local.is-production
  application_name           = "${local.application_name_short}-visualiser"
  public_subnets             = data.aws_subnets.shared-public.ids
  loadbalancer_ingress_rules = local.visualiser_lb_ingress_rules
  loadbalancer_egress_rules  = local.visualiser_lb_egress_rules
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = "eu-west-2"
  enable_deletion_protection = local.is-production
  idle_timeout               = 60
  tags                       = local.tags
}

resource "aws_lb_target_group" "visualiser" {
  name_prefix          = "vis-"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    path                = "/health"
    port                = "8080"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }

  tags = merge(local.tags, { Name = "${local.application_name_short}-${local.environment}-visualiser" })
}

# Visualiser ALB Listener
resource "aws_lb_listener" "visualiser_https" {
  load_balancer_arn = module.lb_visualiser.load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = module.visualiser_cert.certificate_arn

  # Default action: reject anything that doesn't carry the CloudFront custom header
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

# Only forward to the visualiser target group when the CloudFront custom header is present
resource "aws_lb_listener_rule" "visualiser_origin_verify" {
  listener_arn = aws_lb_listener.visualiser_https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.visualiser.arn
  }

  condition {
    http_header {
      http_header_name = "X-CFO-DMS-Origin-Verify"
      values           = [random_password.cloudfront_visualiser.result]
    }
  }
}

