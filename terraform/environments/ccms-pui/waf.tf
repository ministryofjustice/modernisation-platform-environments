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
    "80.195.27.199/32",  # Krupal IP
    "35.179.83.235/32",  # Secure Browser
    "13.43.42.69/32"     # Secure Browser
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

  # Restrict access to trusted IPs only - Non-Prod environments only
  dynamic "rule" {
    for_each = !local.is-production ? [1] : [1] # Temprorarily enable for Prod as well - to be removed when Geo Match is live
    content {
      name     = "${local.application_name}-waf-ip-set"
      priority = 2

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
