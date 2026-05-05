module "ai_gateway_ip_set" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-wafv2.git//modules/ip-set?ref=2b8c16dea7b9f9bab0d1a3d34abd7f587d98bf09" # v1.1.0

  name               = "ai-gateway-allowlist-${local.environment}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.environment_configuration.ai_gateway_ingress_allowlist
}

module "ai_gateway_waf" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-wafv2.git?ref=2b8c16dea7b9f9bab0d1a3d34abd7f587d98bf09" # v1.1.0

  name  = "ai-gateway-${local.environment}"
  scope = "REGIONAL"

  default_action = "allow"

  rules = {
    ip-allowlist = {
      priority = 1
      action   = "allow"

      statement = {
        ip_set_reference_statement = {
          arn = module.ai_gateway_ip_set.arn
        }
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
    }

    block-all = {
      priority = 99
      action   = "block"

      statement = {
        not_statement = {
          statement = {
            ip_set_reference_statement = {
              arn = module.ai_gateway_ip_set.arn
            }
          }
        }
      }
    }
  }

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "ai-gateway-waf"
    sampled_requests_enabled   = true
  }
}
