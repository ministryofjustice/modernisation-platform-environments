#####################################################################################
### AWS WAF Web ACL for OAS Application Load Balancer
#####################################################################################

resource "aws_wafv2_web_acl" "oas_waf" {
  count       = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name        = "oas-web-acl-${local.environment}"
  description = "WAF Web ACL for OAS Application Load Balancer with managed rule groups"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rules - Core Rule Set (CRS)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      count {} # COUNT mode - monitor only, do not block
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - SQL Injection Protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      count {} # COUNT mode - monitor only, do not block
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      count {} # COUNT mode - monitor only, do not block
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "oas-waf-${local.environment}"
    sampled_requests_enabled   = true
  }

  tags = merge(
    local.tags,
    {
      Name = "oas-${local.environment}-web-acl"
    }
  )
}

#####################################################################################
### WAF Web ACL Association with ALB
#####################################################################################

resource "aws_wafv2_web_acl_association" "oas_alb" {
  count        = contains(["preproduction", "development"], local.environment) ? 1 : 0
  resource_arn = aws_lb.oas_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.oas_waf[0].arn
}

#####################################################################################
### WAF Logging Configuration (S3)
#####################################################################################

# S3 bucket for WAF logs
resource "aws_s3_bucket" "waf_logs" {
  count  = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket = "aws-waf-logs-oas-${local.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    local.tags,
    {
      Name = "oas-${local.environment}-waf-logs"
    }
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs_lifecycle" {
  count  = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket = aws_s3_bucket.waf_logs[0].id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  count  = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket = aws_s3_bucket.waf_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_wafv2_web_acl_logging_configuration" "oas_waf_logging" {
  count                   = contains(["preproduction", "development"], local.environment) ? 1 : 0
  resource_arn            = aws_wafv2_web_acl.oas_waf[0].arn
  log_destination_configs = ["${aws_s3_bucket.waf_logs[0].arn}"]
}

#####################################################################################
### Notes:
#####################################################################################
# 1. All rules are in COUNT mode - they will only log matches, not block traffic
# 2. After 1-2 weeks of monitoring, switch to BLOCK mode by changing:
#    override_action { count {} } -> override_action { none {} }
# 3. Sampled requests are enabled for all rules for visibility
# 4. CloudWatch metrics are enabled for monitoring rule effectiveness
# 5. WAF logs are stored in S3 with lifecycle policy (90 days -> Glacier, 1 year delete)
#
# To switch a rule to BLOCK mode after validation:
# override_action {
#   none {} # Enable blocking
# }
#
# IMPORTANT: You may need to detach the existing FMM-managed Web ACL first:
# aws wafv2 disassociate-web-acl \
#   --resource-arn "arn:aws:elasticloadbalancing:eu-west-2:ACCOUNT_ID:loadbalancer/app/oas-lb/LOAD_BALANCER_ID" \
#   --region eu-west-2
