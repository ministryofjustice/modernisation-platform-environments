##############################################
### Locals for ELB Module
##############################################
locals {
  loadbalancer_ingress_rules = {
    "lb_ingress" = {
      description     = "Loadbalancer ingress rule from CloudFront"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = ["13.124.199.0/24", "130.176.0.0/18", "130.176.128.0/21", "130.176.136.0/23", "130.176.140.0/22", "130.176.144.0/20", "130.176.160.0/19", "130.176.192.0/19", "130.176.64.0/21", "130.176.72.0/22", "130.176.76.0/24", "130.176.78.0/23", "130.176.80.0/22", "130.176.86.0/23", "130.176.88.0/21", "130.176.96.0/19", "15.158.0.0/16", "18.68.0.0/16", "204.246.166.0/24", "205.251.218.0/24", "3.172.0.0/18", "3.172.64.0/18", "3.29.57.0/26", "52.46.0.0/18", "52.82.128.0/23", "52.82.134.0/23", "54.182.128.0/20", "54.182.144.0/21", "54.182.154.0/23", "54.182.156.0/22", "54.182.160.0/21", "54.182.172.0/22", "54.182.176.0/21", "54.182.184.0/22", "54.182.188.0/23", "54.182.224.0/21", "54.182.240.0/21", "54.182.248.0/22", "54.239.134.0/23", "54.239.170.0/23", "54.239.204.0/22", "54.239.208.0/21", "64.252.128.0/18", "64.252.64.0/18", "70.132.0.0/18"]
      security_groups = []
    }
  }

  loadbalancer_egress_rules = {
    "lb_egress" = {
      description     = "Loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
}


##############################################
### ELB Instance for OAS Application Servers
##############################################
module "lb_access_logs_enabled" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=6f59e1ce47df66bc63ee9720b7c58993d1ee64ee"
  providers = {
    aws.bucket-replication = aws
  }
  vpc_all                    = "${local.vpc_name}-${local.environment}"
  force_destroy_bucket       = true # enables destruction of logging bucket
  application_name           = local.application_name
  public_subnets             = data.aws_subnets.shared-public.ids
  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
  loadbalancer_egress_rules  = local.loadbalancer_egress_rules
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = "eu-west-2"
  enable_deletion_protection = false
  idle_timeout               = 60

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} lb_module" }
  )

}

resource "aws_lb_target_group" "oas_ec2_target_group" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  name_prefix          = "oas-ec"
  port                 = 9500
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  health_check {
    path                = "/console/em"
    port                = "9500"
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 3
    matcher             = "200-399"
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-ec2-target-group" }
  )
}

resource "aws_lb_target_group_attachment" "oas_ec2_attachment" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
  target_id        = aws_instance.oas_app_instance_new[0].id
  port             = 9500
}

# Target Group for Analytics (port 9502)
resource "aws_lb_target_group" "oas_analytics_target_group" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  name_prefix          = "oas-an"
  port                 = 9502
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  health_check {
    path                = "/analytics"
    port                = "9502"
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 3
    matcher             = "200-399"
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-analytics-target-group" }
  )
}

resource "aws_lb_target_group_attachment" "oas_analytics_attachment" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  target_group_arn = aws_lb_target_group.oas_analytics_target_group[0].arn
  target_id        = aws_instance.oas_app_instance_new[0].id
  port             = 9502
}




resource "aws_lb_listener" "https_listener" {
  #checkov:skip=CKV_AWS_103
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  depends_on        = [aws_acm_certificate_validation.external]
  load_balancer_arn = module.lb_access_logs_enabled.load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external[0].arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# Listener rule for /console/em -> port 9500
resource "aws_lb_listener_rule" "console_em_rule" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  listener_arn = aws_lb_listener.https_listener[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
  }

  condition {
    path_pattern {
      values = ["/console/em*"]
    }
  }
}

# Listener rule for /analytics -> port 9502
resource "aws_lb_listener_rule" "analytics_rule" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  listener_arn = aws_lb_listener.https_listener[0].arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.oas_analytics_target_group[0].arn
  }

  condition {
    path_pattern {
      values = ["/analytics*"]
    }
  }
}