# Duplicate resource to get around provider error

resource "aws_wafv2_web_acl" "waf" {
  #checkov:skip=CKV2_AWS_31:add this later depends on datadog todo
  count       = var.scope != "CLOUDFRONT" ? 1 : 0
  name        = "${var.waf_name}-waf"
  description = "${var.waf_name}-waf from terraform"
  scope       = var.scope

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = var.waf_IP_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.ipset[rule.value.name].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = local.default_waf_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.managed_rule_group_statement.name
          vendor_name = lookup(rule.value.managed_rule_group_statement, "vendor_name", "AWS")

          dynamic "rule_action_override" {
            for_each = lookup(rule.value.managed_rule_group_statement, "rule_action_override", [])
            content {
              name = rule_action_override.value.name

              dynamic "action_to_use" {
                for_each = contains(keys(rule_action_override.value.action_to_use), "count") ? [1] : []
                content {
                  count {}
                }
              }

              dynamic "action_to_use" {
                for_each = contains(keys(rule_action_override.value.action_to_use), "block") ? [1] : []
                content {
                  block {}
                }
              }

              dynamic "action_to_use" {
                for_each = contains(keys(rule_action_override.value.action_to_use), "allow") ? [1] : []
                content {
                  allow {}
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.waf_geoIP_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        block {}
      }

      statement {
        not_statement {
          statement {
            geo_match_statement {
              country_codes = rule.value.geo_match_statement.country_codes

              forwarded_ip_config {
                header_name       = "X-Forwarded-For"
                fallback_behavior = "MATCH"
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  tags = local.tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAF"
    sampled_requests_enabled   = true
  }

  depends_on = [aws_wafv2_ip_set.ipset]
}

resource "aws_wafv2_web_acl" "cf" {
  #checkov:skip=CKV2_AWS_31:add this later depends on datadog todo
  count       = var.scope != "CLOUDFRONT" ? 0 : 1
  name        = "${var.waf_name}-waf"
  description = "${var.waf_name}-waf from terraform"
  scope       = var.scope
  provider    = aws.us-east-1

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = var.waf_IP_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.ipset[rule.value.name].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = local.default_waf_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.managed_rule_group_statement.name
          vendor_name = lookup(rule.value.managed_rule_group_statement, "vendor_name", "AWS")

          dynamic "rule_action_override" {
            for_each = lookup(rule.value.managed_rule_group_statement, "rule_action_override", [])
            content {
              name = rule_action_override.value.name

              dynamic "action_to_use" {
                for_each = contains(keys(rule_action_override.value.action_to_use), "count") ? [1] : []
                content {
                  count {}
                }
              }

              dynamic "action_to_use" {
                for_each = contains(keys(rule_action_override.value.action_to_use), "block") ? [1] : []
                content {
                  block {}
                }
              }

              dynamic "action_to_use" {
                for_each = contains(keys(rule_action_override.value.action_to_use), "allow") ? [1] : []
                content {
                  allow {}
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.waf_geoIP_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        block {}
      }

      statement {
        not_statement {
          statement {
            geo_match_statement {
              country_codes = rule.value.geo_match_statement.country_codes
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  tags = local.tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAF"
    sampled_requests_enabled   = true
  }

  depends_on = [aws_wafv2_ip_set.ipset]
}

resource "aws_wafv2_ip_set" "ipset" {
  for_each           = var.waf_IP_rules
  name               = each.value.name
  description        = each.value.description
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = each.value.ip_addresses

  tags = local.tags
}