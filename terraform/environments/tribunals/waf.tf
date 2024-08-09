resource "aws_wafv2_ip_set" "allowed_ip_set" {
  name  = "allowed-ip-set"
  scope = "REGIONAL"
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
  name  = "tribunals-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "common-rule-set"
    priority = 1

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
    priority = 2

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
    priority = 3

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
      metric_name                = "BlockNonAllowedIPsMetrics"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
  resource_arn = aws_lb.tribunals_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.tribunals_web_acl.arn
}