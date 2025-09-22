# WAF IP Set
resource "aws_wafv2_ip_set" "allowed_ip_set" {
  provider = aws.us-east-1
  name     = "allowed-ip-set"
  scope    = "CLOUDFRONT"
  addresses = [
    "20.26.11.71/32", "20.26.11.108/32", "20.49.214.199/32",
    "20.49.214.228/32", "51.149.249.0/29", "51.149.249.32/29",
    "51.149.250.0/24", "128.77.75.64/26", "194.33.200.0/21",
    "194.33.216.0/23", "194.33.218.0/24", "194.33.248.0/29",
    "194.33.249.0/29", "194.33.196.0/25", "194.33.192.0/25"
  ]
  ip_address_version = "IPV4"
}

resource "aws_wafv2_web_acl" "tribunals_web_acl" {
  #checkov:skip=CKV2_AWS_31:"WAF logging is not required for this implementation as we use CloudWatch metrics for monitoring"
  provider = aws.us-east-1
  name     = "tribunals-web-acl"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "allow-siac"
    priority = 0
    action {
      allow {}
    }
    statement {
      byte_match_statement {
        search_string = "siac.tribunals.gov.uk"
        field_to_match {
          single_header {
            name = "host"
          }
        }
        positional_constraint = "EXACTLY"
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-siac"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "log4j-mitigation"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "Log4jMitigationMetrics"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "common-rule-set"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        rule_action_override {
          action_to_use {
            allow {}
          }
          name = "SizeRestrictions_BODY"
        }
        rule_action_override {
          action_to_use {
            allow {}
          }
          name = "CrossSiteScripting_COOKIE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetrics"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AllowSpecificIPsForAdminAndSecurePaths"
    priority = 3

    action {
      allow {}
    }

    statement {
      and_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.allowed_ip_set.arn
          }
        }
        statement {
          or_statement {
            statement {
              byte_match_statement {
                field_to_match {
                  uri_path {}
                }
                positional_constraint = "CONTAINS"
                search_string         = "admin"
                text_transformation {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            }
            statement {
              byte_match_statement {
                field_to_match {
                  uri_path {}
                }
                positional_constraint = "CONTAINS"
                search_string         = "secure"
                text_transformation {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AdminAndSecurePathAllowMetrics"
      sampled_requests_enabled   = true
    }
  }

  custom_response_body {
    key          = "CustomResponseBodyKey1"
    content_type = "TEXT_HTML"
    content      = "<h1>Secure Page</h1> <h3>This area of the website now requires elevated security.</h3> <br> <h3>If you believe you should be able to access this page please send an email to: - dts-legacy-apps-support-team@hmcts.net</h3>"
  }

  rule {
    name     = "BlockNonAllowedIPsForAdminAndSecurePaths"
    priority = 4

    action {
      block {
        custom_response {
          response_code            = 403
          custom_response_body_key = "CustomResponseBodyKey1"
        }
      }
    }

    statement {
      and_statement {
        statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.allowed_ip_set.arn
              }
            }
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.blocked_paths.arn
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockNonAllowedIPsMetrics"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "tribunals-web-acl"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_regex_pattern_set" "blocked_paths" {
  provider = aws.us-east-1
  name     = "blocked-paths"
  scope    = "CLOUDFRONT"

  regular_expression {
    regex_string = "(?i)^/admin(/.*)?$"
  }

  regular_expression {
    regex_string = "(?i)^/secure(/.*)?$"
  }
}

# CloudWatch Log Group for WAF Logging
resource "aws_cloudwatch_log_group" "tribunals_waf_logs" {
  #checkov:skip=CKV_AWS_158:"Ensure that CloudWatch Log Group is encrypted by KMS"
  name              = "aws-waf-logs-tribunals-web-acl"
  retention_in_days = 365
  provider          = aws.us-east-1
  tags = {
    Environment = local.environment
    Component   = "WAF"
  }
}

# IAM Policy for WAF Logging
resource "aws_cloudwatch_log_resource_policy" "tribunals_waf_log_policy" {
  policy_name     = "WAFLoggingPolicy-TribunalsWebACL"
  policy_document = data.aws_iam_policy_document.tribunals_waf_log_policy.json
  provider        = aws.us-east-1
}

data "aws_iam_policy_document" "tribunals_waf_log_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["waf.amazonaws.com"]
    }
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.tribunals_waf_logs.arn}:*"
    ]
  }
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "tribunals_waf_logging" {
  resource_arn            = aws_wafv2_web_acl.tribunals_web_acl.arn
  log_destination_configs = [aws_cloudwatch_log_group.tribunals_waf_logs.arn]
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
  provider = aws.us-east-1
  depends_on = [
    aws_wafv2_web_acl.tribunals_web_acl,
    aws_cloudwatch_log_group.tribunals_waf_logs,
    aws_cloudwatch_log_resource_policy.tribunals_waf_log_policy
  ]
}