resource "aws_wafv2_ip_set" "allowed_ip_set" {
  provider  = aws.us-east-1
  name      = "allowed-ip-set"
  scope     = "CLOUDFRONT"
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
  provider = aws.us-east-1
  name     = "tribunals-web-acl"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
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

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "tribunals-web-acl"
    sampled_requests_enabled   = true
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