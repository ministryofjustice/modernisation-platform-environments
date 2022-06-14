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
  bucket_prefix = "aws-waf-logs-citrix-moj"
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
