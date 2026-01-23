##############################################
### Locals for ELB Module
##############################################
locals {
  # Define CIDR blocks once to avoid repetition
  moj_cidr_blocks = [
    "51.149.251.0/24",     # MOJO
    "51.149.250.0/24",     # MOJO
    "10.184.0.0/14",       # MOJO device IP taken from CCMS
    "35.176.254.38/32",    # Workspace
    "52.56.212.11/32",     # Workspace
    "35.177.173.197/32",   # Workspace
    "10.200.0.0/16",       # Internal network
    "10.200.16.0/20"       # LZ Prod Shared-Service Workspaces
  ]

  loadbalancer_ingress_rules = {
    "lb_ingress_80" = {
      description     = "Loadbalancer ingress rule for HTTP (redirects to HTTPS)"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = local.moj_cidr_blocks
      security_groups = []
    }
    "lb_ingress_443" = {
      description     = "Loadbalancer ingress rule for HTTPS from MOJO devices and LZ Shared-Service Workspaces"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = local.moj_cidr_blocks
      security_groups = []
    }
    "lb_ingress_9500" = {
      description     = "Loadbalancer ingress rule for HTTP 9500 (Console/EM)"
      from_port       = 9500
      to_port         = 9500
      protocol        = "tcp"
      cidr_blocks     = local.moj_cidr_blocks
      security_groups = []
    }
    "lb_ingress_9502" = {
      description     = "Loadbalancer ingress rule for HTTP 9502 (Analytics/DV)"
      from_port       = 9502
      to_port         = 9502
      protocol        = "tcp"
      cidr_blocks     = local.moj_cidr_blocks
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
  internal_lb                = true
  subnets                    = data.aws_subnets.shared-private.ids
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
    path                = "/console"
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




resource "aws_lb_listener" "http_listener" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  load_balancer_arn = module.lb_access_logs_enabled.load_balancer.arn
  port              = 80
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

# HTTP Listener on port 9500 for WebLogic Console and Enterprise Manager
# resource "aws_lb_listener" "http_9500_listener" {
#   count = contains(["test", "preproduction"], local.environment) ? 1 : 0

#   load_balancer_arn = module.lb_access_logs_enabled.load_balancer.arn
#   port              = 9500
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
#   }
# }

# Listener rule for /console on port 9500
# resource "aws_lb_listener_rule" "console_9500_rule" {
#   count = contains(["test", "preproduction"], local.environment) ? 1 : 0

#   listener_arn = aws_lb_listener.http_9500_listener[0].arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
#   }

#   condition {
#     path_pattern {
#       values = ["/console*"]
#     }
#   }
# }

# Listener rule for /em on port 9500
# resource "aws_lb_listener_rule" "em_9500_rule" {
#   count = contains(["test", "preproduction"], local.environment) ? 1 : 0

#   listener_arn = aws_lb_listener.http_9500_listener[0].arn
#   priority     = 101

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
#   }

#   condition {
#     path_pattern {
#       values = ["/em*"]
#     }
#   }
# }

# HTTP Listener on port 9502 for Analytics and Data Visualization
# resource "aws_lb_listener" "http_9502_listener" {
#   count = contains(["test", "preproduction"], local.environment) ? 1 : 0

#   load_balancer_arn = module.lb_access_logs_enabled.load_balancer.arn
#   port              = 9502
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.oas_analytics_target_group[0].arn
#   }
# }

# Listener rule for /analytics on port 9502
# resource "aws_lb_listener_rule" "analytics_9502_rule" {
#   count = contains(["test", "preproduction"], local.environment) ? 1 : 0

#   listener_arn = aws_lb_listener.http_9502_listener[0].arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.oas_analytics_target_group[0].arn
#   }

#   condition {
#     path_pattern {
#       values = ["/analytics*"]
#     }
#   }
# }

# Listener rule for /dv on port 9502
# resource "aws_lb_listener_rule" "dv_9502_rule" {
#   count = contains(["test", "preproduction"], local.environment) ? 1 : 0

#   listener_arn = aws_lb_listener.http_9502_listener[0].arn
#   priority     = 101

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.oas_analytics_target_group[0].arn
#   }

#   condition {
#     path_pattern {
#       values = ["/dv*"]
#     }
#   }
# }

# HTTPS Listener rules (keeping for SSL access)
# Listener rule for /console on HTTPS
resource "aws_lb_listener_rule" "console_https_rule" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  listener_arn = aws_lb_listener.https_listener[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
  }

  condition {
    path_pattern {
      values = ["/console*"]
    }
  }
}

# Listener rule for /em on HTTPS
resource "aws_lb_listener_rule" "em_https_rule" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  listener_arn = aws_lb_listener.https_listener[0].arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
  }

  condition {
    path_pattern {
      values = ["/em*"]
    }
  }
}

# Listener rule for /analytics on HTTPS
resource "aws_lb_listener_rule" "analytics_https_rule" {
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

# Listener rule for /dv on HTTPS
resource "aws_lb_listener_rule" "dv_https_rule" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  listener_arn = aws_lb_listener.https_listener[0].arn
  priority     = 210

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.oas_analytics_target_group[0].arn
  }

  condition {
    path_pattern {
      values = ["/dv*"]
    }
  }
}

# Listener rule for /bi-security-login on HTTPS
resource "aws_lb_listener_rule" "bi_security_login_https_rule" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  listener_arn = aws_lb_listener.https_listener[0].arn
  priority     = 220

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.oas_analytics_target_group[0].arn
  }

  condition {
    path_pattern {
      values = ["/bi-security-login*"]
    }
  }
}