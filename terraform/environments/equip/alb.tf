##############################################################
# S3 Bucket Creation
# For root account id, refer below link
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
##############################################################

data "aws_acm_certificate" "production_cert" {
  count    = local.environment == "production" ? 1 : 0
  domain   = "equip.service.justice.gov.uk"
  statuses = ["ISSUED"]
}

#Load balancer needs to be publically accessible
#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "citrix_alb" {

  name               = format("alb-%s-%s-citrix", local.application_name, local.environment)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [data.aws_subnet.public_subnet_a.id, data.aws_subnet.public_subnet_b.id]

  enable_deletion_protection = true
  drop_invalid_header_fields = true
  enable_waf_fail_open       = true
  ip_address_type            = "ipv4"

  tags = merge(local.tags,
    { Name = format("alb-%s-%s-citrix", local.application_name, local.environment)
      Role = "Equip public load balancer"
    }
  )

  access_logs {
    bucket  = aws_s3_bucket.this.id
    enabled = "true"
  }

}

resource "aws_lb_target_group" "lb_tg_http" {
  name        = format("tg-%s-%s-80", local.application_name, local.environment)
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.shared.id
  port        = "80"

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTP"
    port                = 80
    timeout             = 10
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = local.tags
}

resource "aws_lb_target_group" "lb_tg_https" {
  name        = format("tg-%s-%s-443", local.application_name, local.environment)
  target_type = "ip"
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.shared.id
  port        = "443"

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTPS"
    port                = 80
    timeout             = 10
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = local.tags
}

resource "aws_lb_target_group_attachment" "lb_tga_80" {
  target_group_arn = aws_lb_target_group.lb_tg_http.arn
  target_id        = aws_network_interface.adc_vip_interface.private_ip_list[0]
  port             = 80
}

resource "aws_lb_target_group_attachment" "lb_tga_443" {
  target_group_arn = aws_lb_target_group.lb_tg_http.arn
  target_id        = aws_network_interface.adc_vip_interface.private_ip_list[0]
  port             = 443
}

resource "aws_lb_listener" "lb_listener_https" {
  #checkov:skip=CKV_AWS_103
  load_balancer_arn = aws_lb.citrix_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.lb_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.lb_tg_http.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "lb_listener_http" {
  load_balancer_arn = aws_lb.citrix_alb.arn
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


#########################################################################
# WAF Rules for Application Load balancer
#########################################################################

resource "aws_wafv2_web_acl" "wafv2_web_acl" {
  name        = "aws_wafv2_webacl"
  description = "Web ACL for ALB"
  scope       = "REGIONAL"

  default_action {
    allow {
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "aws_wafv2_webacl"
    sampled_requests_enabled   = true
  }
  rule {
    name     = "WAF_Known_bad"
    priority = 1
    override_action {
      none {
      }
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAF_Known_bad"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "WAF_AmazonIP_reputation"
    priority = 2
    override_action {
      count {
      }
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAF_AmazonIP_reputation"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "WAF_Core_rule"
    priority = 3
    override_action {
      count {
      }
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        excluded_rule {
          name = "SizeRestrictions_QUERYSTRING"
        }

        excluded_rule {
          name = "SizeRestrictions_BODY"
        }

        excluded_rule {
          name = "GenericRFI_QUERYARGUMENTS"
        }

        excluded_rule {
          name = "NoUserAgent_HEADER"
        }

        scope_down_statement {
          geo_match_statement {
            country_codes = ["GB", "IN"]
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAF_Core_rule"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "WAF_AnonymousIP"
    priority = 4
    override_action {
      count {
      }
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAF_AnonymousIP"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "WAF_SQLdatabase"
    priority = 5
    override_action {
      count {
      }
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAF_SQLdatabase"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "WAF_Windows_OS"
    priority = 6
    override_action {
      count {
      }
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesWindowsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAF_Windows_OS"
      sampled_requests_enabled   = true
    }
  }
  tags = {
    Name = "aws_wafv2_webacl citrix"
  }
}


resource "aws_wafv2_web_acl_association" "aws_lb_waf_association" {
  resource_arn = aws_lb.citrix_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.wafv2_web_acl.arn
}


#tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning tfsec:ignore:aws-s3-block-public-acls tfsec:ignore:aws-s3-block-public-policy tfsec:ignore:aws-s3-ignore-public-acls tfsec:ignore:aws-s3-no-public-buckets tfsec:ignore:aws-s3-specify-public-access-block
resource "aws_s3_bucket" "wafv2_webacl_logs" {
  bucket        = "aws-waf-logs-citrix-moj"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config-waf" {
  bucket = aws_s3_bucket.wafv2_webacl_logs.bucket

  rule {
    id = "log_deletion"

    expiration {
      days = 90
    }

    filter {
      and {
        prefix = ""

        tags = {
          rule      = "waf-log-deletion"
          autoclean = "true"
        }
      }
    }
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "default_encryption_waf_logs" {
  bucket = aws_s3_bucket.wafv2_webacl_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "wafv2_webacl_logs" {
  log_destination_configs = ["${aws_s3_bucket.wafv2_webacl_logs.arn}"]
  resource_arn            = aws_wafv2_web_acl.wafv2_web_acl.arn
}
