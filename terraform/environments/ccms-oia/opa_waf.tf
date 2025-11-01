# WAF FOR OPAHUB APP

resource "aws_wafv2_ip_set" "opahub_waf_ip_set" {
  name               = "${local.opa_app_name}-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_a,
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_b,
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_c,
    local.application_data.accounts[local.environment].mp_nat_gateway_a,
    local.application_data.accounts[local.environment].mp_nat_gateway_b,
    local.application_data.accounts[local.environment].mp_nat_gateway_c,
    "35.176.254.38/32",  # Temp AWS PROD Workspace
    "35.177.173.197/32", # Temp AWS PROD Workspace
    "52.56.212.11/32"    # Temp AWS PROD Workspace
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-ip-set", local.opa_app_name)) }
  )
}


# Web Deteminations Open only in Production - temporary restrict til we go live 
resource "aws_wafv2_ip_set" "opahub_waf_ip_set_web_determinations" {
  count              = local.is-production ? 1 : 0
  name               = "${local.opa_app_name}-waf-ip-set-web-determinations"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "Trusted IPs for Web Determinations path"

  addresses = [
    local.application_data.accounts[local.environment].mp_nat_gateway_a,
    local.application_data.accounts[local.environment].mp_nat_gateway_b,
    local.application_data.accounts[local.environment].mp_nat_gateway_c,
    "89.45.177.118/32", # Sahid
    "80.195.27.199/32"  # Krupal IP
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-ip-set-web-determinations", local.opa_app_name)) }
  )
}


# Default block on the WAF for now - only allow trusted IPs above
resource "aws_wafv2_web_acl" "opahub_web_acl" {
  name        = "${local.opa_app_name}-web-acl"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for opahub Application Load Balancer"

  default_action {
    block {}
  }

  # Rule 1: AWS Managed Rules Common Rule Set with overrides
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CrossSiteScripting_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #### WHEN READY TO GO LIVE WITH WEB DETERMINATIONS, SWITCH TO GEO MATCH INSTEAD OF IP SET

  # Rule 2: /opa/web-determinations/* (Prod only)
  dynamic "rule" {
    for_each = local.is-production ? [1] : []
    content {
      name     = "${local.opa_app_name}-waf-web-determinations"
      priority = 2

      action {
        allow {}
      }

      statement {
        and_statement {
          statement {
            byte_match_statement {
              search_string = "/opa/web-determinations/"
              field_to_match {
                uri_path {}
              }
              positional_constraint = "STARTS_WITH"
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }

          statement {
            ip_set_reference_statement {
              arn = aws_wafv2_ip_set.opahub_waf_ip_set_web_determinations[0].arn
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.opa_app_name}-waf-web-determinations"
        sampled_requests_enabled   = true
      }
    }
  }

  #### WHEN READY TO GO LIVE WITH WEB DETERMINATIONS, SWITCH TO GEO MATCH INSTEAD OF IP SET

  # # Rule 2: /opa/web-determinations/* (Prod only)
  # dynamic "rule" {
  #   for_each = local.is-production ? [1] : []
  #   content {
  #     name     = "${local.opa_app_name}-waf-web-determinations"
  #     priority = 2

  #     action {
  #       allow {}
  #     }

  #     statement {
  #       and_statement {
  #         # Condition 1: URI path starts with /opa/web-determinations/
  #         statement {
  #           byte_match_statement {
  #             search_string = "/opa/web-determinations/"
  #             field_to_match {
  #               uri_path {}
  #             }
  #             positional_constraint = "STARTS_WITH"
  #             text_transformation {
  #               priority = 0
  #               type     = "NONE"
  #             }
  #           }
  #         }

  #         # Condition 2: Request originates from United Kingdom
  #         statement {
  #           geo_match_statement {
  #             country_codes = ["GB"]
  #           }
  #         }
  #       }
  #     }

  #     visibility_config {
  #       cloudwatch_metrics_enabled = true
  #       metric_name                = "${local.opa_app_name}-waf-web-determinations"
  #       sampled_requests_enabled   = true
  #     }
  #   }
  # }

  # Rule 3: Allow OPA HUB access from trusted IPs
  rule {
    name     = "${local.opa_app_name}-waf-ip-set"
    priority = local.is-production ? 3 : 2

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.opahub_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.opa_app_name}-waf-ipset"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.opa_app_name}-web-acl"
    sampled_requests_enabled   = true
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-web-acl", local.opa_app_name)) }
  )
}


# WAF Logging to CloudWatch
resource "aws_cloudwatch_log_group" "opahub_waf_logs" {
  name              = "aws-waf-logs-${local.opa_app_name}"
  retention_in_days = 180

  tags = merge(local.tags,
    { Name = lower(format("%s-waf-logs", local.opa_app_name)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "opahub_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.opahub_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.opahub_web_acl.arn
}

# Associate the WAF with the OPAHUB Application Load Balancer
resource "aws_wafv2_web_acl_association" "opahub_waf_association" {
  resource_arn = aws_lb.opahub.arn
  web_acl_arn  = aws_wafv2_web_acl.opahub_web_acl.arn
}

rule {
  name     = "CustomXSSBlockExceptSpecificUrisAndIps"
  priority = 1
  action {
    block {}
  }
  statement {
    and_statement {
      statements {
        xss_match_statement {
          field_to_match {
            body {
              oversize_handling = "NO_MATCH"
            }
          }
          text_transformation {
            priority = 0
            type     = "URL_DECODE"
          }
        }
      }
      statements {
        not_statement {
          statement {
            or_statement {
              statements {
                byte_match_statement {
                  field_to_match {
                    uri_path {}
                  }
                  positional_constraint = "EXACTLY"
                  search_string         = "/opa/determinations-server/assess/soap/generic/12.2.1/BillingAssessment"
                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }
              statements {
                byte_match_statement {
                  field_to_match {
                    uri_path {}
                  }
                  positional_constraint = "EXACTLY"
                  search_string         = "/opa/determinations-server/answer/soap/12.2.1/MeritsAssessment"
                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }
              statements {
                byte_match_statement {
                  field_to_match {
                    uri_path {}
                  }
                  positional_constraint = "EXACTLY"
                  search_string         = "/opa/determinations-server/answer/soap/12.2.1/MeansAssessment"
                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }
              statements {
                byte_match_statement {
                  field_to_match {
                    uri_path {}
                  }
                  positional_constraint = "EXACTLY"
                  search_string         = "/opa/determinations-server/answer/soap/12.2.1/BillingAssessment"
                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }
              statements {
                byte_match_statement {
                  field_to_match {
                    uri_path {}
                  }
                  positional_constraint = "EXACTLY"
                  search_string         = "/opa/determinations-server/assess/soap/12.2.1/MeansAssessment"
                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }
              statements {
                byte_match_statement {
                  field_to_match {
                    uri_path {}
                  }
                  positional_constraint = "EXACTLY"
                  search_string         = "/opa/determinations-server/assess/soap/12.2.1/MeritsAssessment"
                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }
            }
          }
        }
      }
      statements {
        not_statement {
          statement {
            ip_set_reference_statement {
              arn = aws_wafv2_ip_set.opahub_waf_ip_set_web_determinations[0].arn
            }
          }
        }
      }
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CustomXSSBlockExceptSpecificUrisAndIps"
    sampled_requests_enabled   = true
  }
}

rule {
  name     = "AllowOversizedBodiesForExemptURIsAndIPs"
  priority = 2
  action {
    allow {}
  }
  statement {
    and_statement {
      statements {
        size_constraint_statement {
          comparison_operator = "GT"
          size                = 8192
          field_to_match {
            body {
              oversize_handling = "MATCH"
            }
          }
          text_transformation {
            priority = 0
            type     = "NONE"
          }
        }
      }
      statements {
        or_statement {
          statements {
            byte_match_statement {
              search_string       = "/opa/determinations-server/assess/soap/generic/12.2.1/BillingAssessment"
              field_to_match {
                uri_path {}
              }
              positional_constraint = "EXACTLY"
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }
          statements {
            byte_match_statement {
              search_string       = "/opa/determinations-server/answer/soap/12.2.1/MeritsAssessment"
              field_to_match {
                uri_path {}
              }
              positional_constraint = "EXACTLY"
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }
          statements {
            byte_match_statement {
              search_string       = "/opa/determinations-server/answer/soap/12.2.1/MeansAssessment"
              field_to_match {
                uri_path {}
              }
              positional_constraint = "EXACTLY"
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }
          statements {
            byte_match_statement {
              search_string       = "/opa/determinations-server/answer/soap/12.2.1/BillingAssessment"
              field_to_match {
                uri_path {}
              }
              positional_constraint = "EXACTLY"
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }
          statements {
            byte_match_statement {
              search_string       = "/opa/determinations-server/assess/soap/generic/12.2.1/MeansAssessment"
              field_to_match {
                uri_path {}
              }
              positional_constraint = "EXACTLY"
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }
          statements {
            byte_match_statement {
              search_string       = "/opa/determinations-server/assess/soap/generic/12.2.1/MeritsAssessment"
              field_to_match {
                uri_path {}
              }
              positional_constraint = "EXACTLY"
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }
        }
      }
      statements {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.opahub_waf_ip_set_web_determinations[0].arn
        }
      }
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AllowOversizedBodiesForExemptURIsAndIPs"
    sampled_requests_enabled   = true
  }
}

rule {
  name     = "BlockOversizedRequestBodies"
  priority = 5
  action {
    block {}
  }
  statement {
    size_constraint_statement {
      comparison_operator = "GT"
      size                = 8192
      field_to_match {
        body {
          oversize_handling = "MATCH"
        }
      }
      text_transformation {
        priority = 0
        type     = "NONE"
      }
    }
  }
  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "BlockOversizedRequestBodies"
  }
}
