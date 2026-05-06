module "waf_ip_set_ai_gateway_allowlist" {
  source  = "terraform-aws-modules/wafv2/aws//modules/ip-set"
  version = "1.1.0"

  name               = "ai-gateway-allowlist-${local.environment}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.environment_configuration.ai_gateway_ingress_allowlist
}

module "waf_ai_gateway" {
  source  = "terraform-aws-modules/wafv2/aws"
  version = "1.1.0"

  name  = "ai-gateway-${local.environment}"
  scope = "REGIONAL"

  default_action = "allow"

  rules = {
    ip-allowlist = {
      priority = 1
      action   = "allow"

      statement = {
        ip_set_reference_statement = {
          arn = module.waf_ip_set_ai_gateway_allowlist.arn
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "ai-gateway-ip-allowlist"
        sampled_requests_enabled   = true
      }
    }

    aws-managed-common-rules = {
      priority        = 10
      override_action = "none"

      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "ai-gateway-common-rules"
        sampled_requests_enabled   = true
      }
    }

    aws-managed-known-bad-inputs = {
      priority        = 20
      override_action = "none"

      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "ai-gateway-known-bad-inputs"
        sampled_requests_enabled   = true
      }
    }

    block-all = {
      priority = 99
      action   = "block"

      statement = {
        not_statement = {
          statement = {
            ip_set_reference_statement = {
              arn = module.waf_ip_set_ai_gateway_allowlist.arn
            }
          }
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "ai-gateway-block-all"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "ai-gateway-waf"
    sampled_requests_enabled   = true
  }
}
