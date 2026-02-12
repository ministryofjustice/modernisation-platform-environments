# WAF FOR SSOGEN APP

resource "aws_wafv2_ip_set" "ssogen_waf_ip_set" {
  count              = local.is-development || local.is-test ? 1 : 0
  name               = "${local.application_name}-ssogen-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
    # local.application_data.accounts[local.environment].sb_vpc
  ]

  tags = merge(
    local.tags,
    { Name = lower(format("%s-%s-ssogen-ip-set", local.application_name, local.environment)) }
  )
}


resource "aws_wafv2_web_acl" "ssogen_web_acl" {
  count       = local.is-development || local.is-test ? 1 : 0
  name        = "${local.application_name}-ssogen-web-acl"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for SSOGEN Application Load Balancer"

  default_action {
    block {}
  }

  # default_action {
  #   block {
  #     custom_response {
  #       custom_response_body_key = "maintenance-response"
  #       response_code            = 503
  #     }
  #   }
  # }

  #   custom_response_body {
  #     key          = "maintenance-response"
  #     content      = <<EOT
  # <!doctype html><html lang="en"><head>
  # <meta charset="utf-8"><title>Maintenance</title>
  # <style>body{font-family:sans-serif;background:#0b1a2b;color:#fff;text-align:center;padding:4rem;}
  # .card{max-width:600px;margin:auto;background:#12243a;padding:2rem;border-radius:10px;}
  # </style></head><body><div class="card">
  # <h1>Scheduled Maintenance</h1>
  # <p>The service is unavailable from 19:00 to 07:00 UK time. Apologies for any inconvenience caused.</p>
  # </div></body></html>
  # EOT
  #     content_type = "TEXT_HTML"
  #   }

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
    # for_each = !local.is-production ? [1] : [1] # Temprorarily enable for Prod as well - to be removed when Geo Match is live
    for_each = local.is-development || local.is-test ? [1] : [0] # Temprorarily enable for Prod as well - to be removed when Geo Match is live
    content {
      name     = "${local.application_name}-ssogen-waf-ip-set"
      priority = 2

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.ssogen_waf_ip_set[count.index].arn
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
    { Name = lower(format("%s-%s-ssogen-web-acl", local.application_name, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.application_name}-ssogen-waf-metrics"
    sampled_requests_enabled   = true
  }
}