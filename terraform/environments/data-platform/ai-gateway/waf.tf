locals {
  waf_blocked_paths = [
    "/metrics",
    "/test",
    "/config/yaml",
  ]
}

data "aws_lb" "ai_gateway" {
  name = local.component_name

  depends_on = [helm_release.ai_gateway_configuration]
}

module "waf_ip_set_ai_gateway_allowlist" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-wafv2.git//modules/ip-set?ref=36eceb918a237a80b69ce98e50b6f83fe17d2401" # v2.1.0

  name               = "${local.component_name}-allowlist-${local.environment}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.environment_configuration.ai_gateway_ingress_allowlist
}

module "waf_ip_set_ai_gateway_admin_allowlist" {
  count  = length(local.environment_configuration.ai_gateway_admin_ingress_allowlist) > 0 ? 1 : 0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-wafv2.git//modules/ip-set?ref=36eceb918a237a80b69ce98e50b6f83fe17d2401" # v2.1.0

  name               = "${local.component_name}-admin-allowlist-${local.environment}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.environment_configuration.ai_gateway_admin_ingress_allowlist
}

module "waf_ai_gateway" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-wafv2.git?ref=36eceb918a237a80b69ce98e50b6f83fe17d2401" # v2.1.0

  name  = "${local.component_name}-${local.environment}"
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
        or_statement = {
          statements = [for path in local.waf_blocked_paths : {
            byte_match_statement = {
              field_to_match = {
                uri_path = {}
              }
              positional_constraint = "STARTS_WITH"
              search_string         = path
              text_transformations = [
                {
                  priority = 0
                  type     = "LOWERCASE"
                }
              ]
            }
          }]
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.component_name}-block-sensitive-paths"
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
        metric_name                = "${local.component_name}-ip-allowlist"
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
        metric_name                = "${local.component_name}-common-rules"
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
        metric_name                = "${local.component_name}-known-bad-inputs"
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
                positional_constraint = "EXACTLY"
                search_string         = "admin.${local.environment_configuration.ai_gateway_hostname}"
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
        metric_name                = "${local.component_name}-allow-admin-authorized"
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
          positional_constraint = "EXACTLY"
          search_string         = "admin.${local.environment_configuration.ai_gateway_hostname}"
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
        metric_name                = "${local.component_name}-block-admin-unauthorized"
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
        metric_name                = "${local.component_name}-ip-allowlist-admin"
        sampled_requests_enabled   = true
      }
    }
  } : {})

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.component_name}-waf"
    sampled_requests_enabled   = true
  }

  create_logging_configuration    = true
  logging_log_destination_configs = [module.waf_ai_gateway_log_group.cloudwatch_log_group_arn]
}
