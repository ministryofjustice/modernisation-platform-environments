# WAF FOR PUI APP

resource "aws_wafv2_ip_set" "pui_waf_ip_set" {
  name               = "${local.application_name}-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_a,
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_b,
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_c,
    "35.176.254.38/32",  # Temp AWS PROD Workspace
    "35.177.173.197/32", # Temp AWS PROD Workspace
    "52.56.212.11/32",   # Temp AWS PROD Workspace
    "80.195.27.199/32"   # Krupal IP
  ]

  tags = merge(
    local.tags,
    { Name = lower(format("%s-%s-ip-set", local.application_name, local.environment)) }
  )
}


resource "aws_wafv2_web_acl" "pui_web_acl" {
  name        = "${local.application_name}-web-acl"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for PUI Application Load Balancer"

  default_action {
    block {}
  }

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

  rule {
    name     = "CustomXSSBlockExceptSpecificUrisAndIps"
    priority = 2
    action {
      allow {}
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
                    search_string       = "/civil/evidenceUpload"
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
                    search_string       = "/civil/CCMS_PD03.form"
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
                    search_string       = "/civil/evidenceUpload.do"
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
          }
        }
        statements {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.pui_waf_ip_set.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "CustomXSSBlockExceptSpecificUrisAndIps"
    }
  }

  rule {
    name     = "AllowOversizedBodiesForExemptURIsAndIPs"
    priority = 3
    action {
      allow {}
    }
    statement {
      and_statement {
        statements {
          or_statement {
            statements {
              byte_match_statement {
                search_string       = "/civil/evidenceUpload"
                field_to_match {
                  uri_path {}
                }
                positional_constraint = "EXACTLY"
                text_transformations {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
            statements {
              byte_match_statement {
                search_string       = "/civil/CCMS_PD03.form"
                field_to_match {
                  uri_path {}
                }
                positional_constraint = "EXACTLY"
                text_transformations {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
            statements {
              byte_match_statement {
                search_string       = "/civil/evidenceUpload.do"
                field_to_match {
                  uri_path {}
                }
                positional_constraint = "EXACTLY"
                text_transformations {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          }
        }
        statements {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.pui_waf_ip_set.arn
          }
        }
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowOversizedBodiesForExemptURIsAndIPs"
    }
  }

  rule {
    name     = "BlockOversizedRequestBodies"
    priority = 4
    action {
      block {}
    }
    statement {
      size_constraint_statement {
        field_to_match {
          body {
            oversize_handling = "MATCH"
          }
        }
        comparison_operator = "GT"
        size                = 8192
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

  # Restrict access to trusted IPs only - Non-Prod environments only
  dynamic "rule" {
    for_each = !local.is-production ? [1] : [1] # Temprorarily enable for Prod as well - to be removed when Geo Match is live
    content {
      name     = "${local.application_name}-waf-ip-set"
      priority = 5

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.pui_waf_ip_set.arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.application_name}-waf-ip-set"
        sampled_requests_enabled   = true
      }
    }
  }


  #### WHEN READY TO GO LIVE, SWITCH TO GEO MATCH INSTEAD OF IP SET ####

  # # Rule 2: Allow UK traffic only (Prod only)
  # dynamic "rule" {
  #   for_each = local.is-production ? [1] : []
  #   content {
  #     name     = "${local.application_name}-waf-geo-uk-only"
  #     priority = 2

  #     action {
  #       allow {}
  #     }

  #     statement {
  #       geo_match_statement {
  #         country_codes = ["GB"]
  #       }
  #     }

  #     visibility_config {
  #       cloudwatch_metrics_enabled = true
  #       metric_name                = "${local.application_name}-waf-geo-uk-only"
  #       sampled_requests_enabled   = true
  #     }
  #   }
  # }



  tags = merge(local.tags,
    { Name = lower(format("%s-%s-web-acl", local.application_name, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.application_name}-waf-metrics"
    sampled_requests_enabled   = true
  }
}

# WAF Logging to CloudWatch
resource "aws_cloudwatch_log_group" "pui_waf_logs" {
  name              = "aws-waf-logs-${local.application_name}"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-waf-logs", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "pui_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.pui_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.pui_web_acl.arn
}

# Associate the WAF with the PUI Application Load Balancer
resource "aws_wafv2_web_acl_association" "pui_waf_association" {
  resource_arn = aws_lb.pui.arn
  web_acl_arn  = aws_wafv2_web_acl.pui_web_acl.arn
}
