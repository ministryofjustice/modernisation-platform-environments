##############################################################
# S3 Bucket Creation
# For root account id, refer below link
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
##############################################################

data "aws_acm_certificate" "equip_cert" {
  domain   = "equip.service.justice.gov.uk"
  statuses = ["ISSUED"]
}

resource "aws_lb" "citrix_alb" {

  name        = format("%s-alb", var.name)
  name_prefix = var.name_prefix

  load_balancer_type = var.load_balancer_type
  #tfsec:ignore:aws-elb-alb-not-public
  internal        = var.internal
  security_groups = [aws_security_group.alb_sg.id]
  subnets         = [data.aws_subnet.public_az_a.id, data.aws_subnet.public_az_b.id]

  enable_deletion_protection       = var.enable_deletion_protection
  idle_timeout                     = var.idle_timeout
  enable_http2                     = var.enable_http2
  desync_mitigation_mode           = var.desync_mitigation_mode
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  enable_waf_fail_open             = var.enable_waf_fail_open
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = merge(
    var.tags,
    var.lb_tags,
    {
      Name = var.name != null ? var.name : var.name_prefix
    },
  )

  access_logs {
    bucket = aws_s3_bucket.this.id
    #    prefix  = "access-logs-alb"
    enabled = "true"
  }

  depends_on = [aws_s3_bucket.this]

  timeouts {
    create = var.load_balancer_create_timeout
    update = var.load_balancer_update_timeout
    delete = var.load_balancer_delete_timeout
  }
}

resource "aws_lb_target_group" "lb_tg_http" {
  name             = "citrix-alb-tgt"
  target_type      = var.lb_tgt_target_type
  protocol         = var.lb_tgt_protocol
  protocol_version = var.lb_tgt_protocol_version
  vpc_id           = data.aws_vpc.shared.id
  port             = var.lb_tgt_port

  health_check {
    enabled             = true
    path                = var.lb_tgt_health_check_path
    interval            = 30
    protocol            = "HTTP"
    port                = 80
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = var.lb_tgt_matcher
  }

  tags = local.tags
}

resource "aws_lb_target_group_attachment" "citrix_instance" {
  target_group_arn = aws_lb_target_group.lb_tg_http.arn
  target_id        = aws_instance.citrix_adc_instance.id
  port             = 80
}

resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_lb.citrix_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.lb_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.lb_tg_http.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "redirect_http_to_https" {
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
