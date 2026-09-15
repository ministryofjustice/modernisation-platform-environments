module "ip_addresses" {
  source = "../../modules/ip_addresses"
}

resource "aws_wafv2_ip_set" "litellm_admin" {
  name               = "litellm-admin"
  description        = "Networks allowed to reach LiteLLM admin routes and UI"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses = distinct(concat(
    module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
    local.application_data.accounts[local.environment].litellm_admin_cidrs
  ))
}

resource "aws_wafv2_web_acl" "litellm" {
  #checkov:skip=CKV_AWS_192: "Log4j rules are included via AWSManagedRulesKnownBadInputsRuleSet, body variants set to count"
  name  = "litellm-gateway"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "admin-routes-restricted"
    priority = 0

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          not_statement {
            statement {
              or_statement {
                statement {
                  byte_match_statement {
                    search_string         = "/bedrock/"
                    positional_constraint = "STARTS_WITH"
                    field_to_match {
                      uri_path {}
                    }
                    text_transformation {
                      priority = 0
                      type     = "NORMALIZE_PATH"
                    }
                  }
                }
                statement {
                  byte_match_statement {
                    search_string         = "/health/liveliness"
                    positional_constraint = "EXACTLY"
                    field_to_match {
                      uri_path {}
                    }
                    text_transformation {
                      priority = 0
                      type     = "NORMALIZE_PATH"
                    }
                  }
                }
              }
            }
          }
        }
        statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.litellm_admin.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "litellm-admin-routes-restricted"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limit-per-key"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = local.application_data.accounts[local.environment].litellm_rate_limit_per_key
        evaluation_window_sec = 300
        aggregate_key_type    = "CUSTOM_KEYS"

        custom_key {
          header {
            name = "authorization"
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
      metric_name                = "litellm-rate-limit-per-key"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "litellm-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  # Prompts routinely contain code, paths, URLs and markup, so body inspection rules only count
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        dynamic "rule_action_override" {
          for_each = ["SizeRestrictions_BODY", "CrossSiteScripting_BODY", "GenericLFI_BODY", "GenericRFI_BODY", "EC2MetaDataSSRF_BODY"]
          content {
            name = rule_action_override.value
            action_to_use {
              count {}
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "litellm-common-rule-set"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"

        dynamic "rule_action_override" {
          for_each = ["Log4JRCE_BODY", "JavaDeserializationRCE_BODY"]
          content {
            name = rule_action_override.value
            action_to_use {
              count {}
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "litellm-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "litellm-gateway"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "litellm" {
  resource_arn = aws_lb.litellm.arn
  web_acl_arn  = aws_wafv2_web_acl.litellm.arn
}

resource "aws_cloudwatch_log_group" "litellm_waf" {
  #checkov:skip=CKV_AWS_158: "Ensure that Cloudwatch Log Group is encrypted using KMS CMK"
  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"
  name              = "aws-waf-logs-litellm-gateway"
  retention_in_days = 30
}

resource "aws_wafv2_web_acl_logging_configuration" "litellm" {
  log_destination_configs = [aws_cloudwatch_log_group.litellm_waf.arn]
  resource_arn            = aws_wafv2_web_acl.litellm.arn

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}
