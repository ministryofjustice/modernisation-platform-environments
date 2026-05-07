data "aws_lb" "ai_gateway" {
  name = "ai-gateway"
}

module "waf_ip_set_ai_gateway_allowlist" {
  source  = "terraform-aws-modules/wafv2/aws//modules/ip-set"
  version = "1.2.0"

  name               = "ai-gateway-allowlist-${local.environment}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.environment_configuration.ai_gateway_ingress_allowlist
}

module "waf_ip_set_ai_gateway_admin_allowlist" {
  count   = length(local.environment_configuration.ai_gateway_admin_ingress_allowlist) > 0 ? 1 : 0
  source  = "terraform-aws-modules/wafv2/aws//modules/ip-set"
  version = "1.2.0"

  name               = "ai-gateway-admin-allowlist-${local.environment}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.environment_configuration.ai_gateway_admin_ingress_allowlist
}

module "waf_ai_gateway" {
  source  = "terraform-aws-modules/wafv2/aws"
  version = "1.2.0"

  name  = "ai-gateway-${local.environment}"
  scope = "REGIONAL"

  default_action = "block"

  association_resource_arns = {
    alb = data.aws_lb.ai_gateway.arn
  }

  rules = merge({
    block-sensitive-paths = {
      priority = 0
      action   = "block"

      statement = {
        byte_match_statement = {
          field_to_match = {
            uri_path = {}
          }
          positional_constraint = "STARTS_WITH"
          search_string         = "/metrics"
          text_transformations = [
            {
              priority = 0
              type     = "LOWERCASE"
            }
          ]
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "ai-gateway-block-sensitive-paths"
        sampled_requests_enabled   = true
      }
    }

    ip-allowlist = {
      priority = 3
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

    }, length(local.environment_configuration.ai_gateway_admin_ingress_allowlist) > 0 ? {
    allow-admin-authorized = {
      priority = 1
      action   = "allow"

      statement = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                field_to_match = {
                  single_header = {
                    name = "host"
                  }
                }
                positional_constraint = "STARTS_WITH"
                search_string         = "admin."
                text_transformations = [
                  {
                    priority = 0
                    type     = "LOWERCASE"
                  }
                ]
              }
            },
            {
              ip_set_reference_statement = {
                arn = module.waf_ip_set_ai_gateway_admin_allowlist[0].arn
              }
            }
          ]
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "ai-gateway-allow-admin-authorized"
        sampled_requests_enabled   = true
      }
    }
    } : {}, length(local.environment_configuration.ai_gateway_admin_ingress_allowlist) > 0 ? {
    block-admin-unauthorized = {
      priority = 2
      action   = "block"

      statement = {
        byte_match_statement = {
          field_to_match = {
            single_header = {
              name = "host"
            }
          }
          positional_constraint = "STARTS_WITH"
          search_string         = "admin."
          text_transformations = [
            {
              priority = 0
              type     = "LOWERCASE"
            }
          ]
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "ai-gateway-block-admin-unauthorized"
        sampled_requests_enabled   = true
      }
    }
  } : {}, length(local.environment_configuration.ai_gateway_admin_ingress_allowlist) > 0 ? {
    ip-allowlist-admin = {
      priority = 4
      action   = "allow"

      statement = {
        ip_set_reference_statement = {
          arn = module.waf_ip_set_ai_gateway_admin_allowlist[0].arn
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "ai-gateway-ip-allowlist-admin"
        sampled_requests_enabled   = true
      }
    }
  } : {})

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "ai-gateway-waf"
    sampled_requests_enabled   = true
  }
}
