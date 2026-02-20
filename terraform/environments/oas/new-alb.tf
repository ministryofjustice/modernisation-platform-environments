##############################################
### Locals for ELB Module
##############################################
locals {
  # Define CIDR blocks once to avoid repetition
  moj_cidr_blocks = [
    "51.149.251.0/24",   # MOJO
    "51.149.250.0/24",   # MOJO
    "10.184.0.0/14",     # MOJO device IP taken from CCMS
    "35.176.254.38/32",  # Workspace
    "52.56.212.11/32",   # Workspace
    "35.177.173.197/32", # Workspace
    "10.200.0.0/16",     # Internal network
    "10.200.16.0/20"     # LZ Prod Shared-Service Workspaces
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
### Security Group for Load Balancer
##############################################
resource "aws_security_group" "lb_security_group" {
  count       = local.environment == "preproduction" ? 1 : 0
  name_prefix = "${local.application_name}-lb-sg"
  description = "Security group for ${local.application_name} load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-lb-sg" }
  )
}

resource "aws_security_group_rule" "lb_ingress_rules" {
  for_each = local.environment == "preproduction" ? local.loadbalancer_ingress_rules : {}

  security_group_id = aws_security_group.lb_security_group[0].id
  type              = "ingress"
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
}

resource "aws_security_group_rule" "lb_egress_rules" {
  for_each = local.environment == "preproduction" ? local.loadbalancer_egress_rules : {}

  security_group_id = aws_security_group.lb_security_group[0].id
  type              = "egress"
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
}

##############################################
### S3 Bucket for Load Balancer Access Logs
##############################################
resource "aws_s3_bucket" "lb_access_logs" {
  count         = local.environment == "preproduction" ? 1 : 0
  bucket_prefix = "${local.application_name}-lb-access-logs-"
  force_destroy = true

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-lb-access-logs" }
  )
}

resource "aws_s3_bucket_versioning" "lb_access_logs" {
  count  = local.environment == "preproduction" ? 1 : 0
  bucket = aws_s3_bucket.lb_access_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lb_access_logs" {
  count  = local.environment == "preproduction" ? 1 : 0
  bucket = aws_s3_bucket.lb_access_logs[0].id

  rule {
    id     = "main"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 730
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 730
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lb_access_logs" {
  count  = local.environment == "preproduction" ? 1 : 0
  bucket = aws_s3_bucket.lb_access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "lb_access_logs" {
  count  = local.environment == "preproduction" ? 1 : 0
  bucket = aws_s3_bucket.lb_access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_elb_service_account" "default" {}

resource "aws_s3_bucket_policy" "lb_access_logs" {
  count  = local.environment == "preproduction" ? 1 : 0
  bucket = aws_s3_bucket.lb_access_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.lb_access_logs[0].arn,
          "${aws_s3_bucket.lb_access_logs[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.default.arn
        }
        Action = "s3:PutObject"
        Resource = [
          "${aws_s3_bucket.lb_access_logs[0].arn}/${local.application_name}/AWSLogs/${local.environment_management.account_ids[terraform.workspace]}/*",
          "${aws_s3_bucket.lb_access_logs[0].arn}/AWSLogs/${local.environment_management.account_ids[terraform.workspace]}/*"
        ]
      },
      {
        Sid = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = [
          "${aws_s3_bucket.lb_access_logs[0].arn}/${local.application_name}/AWSLogs/${local.environment_management.account_ids[terraform.workspace]}/*",
          "${aws_s3_bucket.lb_access_logs[0].arn}/AWSLogs/${local.environment_management.account_ids[terraform.workspace]}/*"
        ]
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.lb_access_logs[0].arn
      }
    ]
  })
}

##############################################
### Application Load Balancer
##############################################
resource "aws_lb" "oas_lb" {
  count                      = local.environment == "preproduction" ? 1 : 0
  name                       = "${local.application_name}-lb"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb_security_group[0].id]
  subnets                    = data.aws_subnets.shared-private.ids
  enable_deletion_protection = false
  idle_timeout               = 60
  enable_http2               = false
  drop_invalid_header_fields = true

  access_logs {
    bucket  = aws_s3_bucket.lb_access_logs[0].id
    prefix  = local.application_name
    enabled = true
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-lb" }
  )
}

resource "aws_lb_target_group" "oas_ec2_target_group" {
  count = local.environment == "preproduction" ? 1 : 0

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
  count = local.environment == "preproduction" ? 1 : 0

  target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
  target_id        = aws_instance.oas_app_instance_new[0].id
  port             = 9500
}

# Target Group for Analytics (port 9502)
resource "aws_lb_target_group" "oas_analytics_target_group" {
  count = local.environment == "preproduction" ? 1 : 0

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
  count = local.environment == "preproduction" ? 1 : 0

  target_group_arn = aws_lb_target_group.oas_analytics_target_group[0].arn
  target_id        = aws_instance.oas_app_instance_new[0].id
  port             = 9502
}




resource "aws_lb_listener" "http_listener" {
  count = local.environment == "preproduction" ? 1 : 0

  load_balancer_arn = aws_lb.oas_lb[0].arn
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
  count = local.environment == "preproduction" ? 1 : 0

  depends_on        = [aws_acm_certificate_validation.external]
  load_balancer_arn = aws_lb.oas_lb[0].arn
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
resource "aws_lb_listener" "http_9500_listener" {
  count = local.environment == "preproduction" ? 1 : 0

  load_balancer_arn = aws_lb.oas_lb[0].arn
  port              = 9500
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
  }
}

# Listener rule for /console on port 9500
resource "aws_lb_listener_rule" "console_9500_rule" {
  count = local.environment == "preproduction" ? 1 : 0

  listener_arn = aws_lb_listener.http_9500_listener[0].arn
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

# Listener rule for /em on port 9500
resource "aws_lb_listener_rule" "em_9500_rule" {
  count = local.environment == "preproduction" ? 1 : 0

  listener_arn = aws_lb_listener.http_9500_listener[0].arn
  priority     = 101

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
  count = local.environment == "preproduction" ? 1 : 0

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
  count = local.environment == "preproduction" ? 1 : 0

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
  count = local.environment == "preproduction" ? 1 : 0

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
  count = local.environment == "preproduction" ? 1 : 0

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
  count = local.environment == "preproduction" ? 1 : 0

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