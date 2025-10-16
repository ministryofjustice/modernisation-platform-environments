resource "aws_wafv2_regex_pattern_set" "ebsapps_blocked_paths" {
  name        = "ebs-blocked-paths"
  description = "Blocked EBS OA_HTML paths"
  scope       = "REGIONAL"

  regular_expression {
    regex_string = "^/OA_HTML/.*SyncServlet"
  }

  regular_expression {
    regex_string = "^/OA_HTML/CZErrorPage\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/CZInfo\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/CZInitializationErrorPage\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/CZInitialize\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/CfgLaunch\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/CfgSebl\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/MySample39\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/configurator/Decache"
  }

  regular_expression {
    regex_string = "^/OA_HTML/configurator/DisplayCXResult"
  }

  regular_expression {
    regex_string = "^/OA_HTML/configurator/UiServlet"
  }

  regular_expression {
    regex_string = "^/OA_HTML/czContainer\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/czEmbed\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/czHeartBeat\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/czJradHeartBeat\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/czSummary\\.jsp"
  }

  tags = merge(local.tags,
    { Name = lower(format("ebs_apps-%s-%s-waf-patterns", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl" "ebsapps_waf_acl" {
  name        = "ebsapps-waf-acl"
  description = "WAF ACL to block access to Oracle EBS configurator endpoints"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "block-ebs-configurator-paths"
    priority = 1

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.ebsapps_blocked_paths.arn

        field_to_match {
          uri_path {}
        }

        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockEBSOAHTMLpaths"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "EBSAppsWAF"
    sampled_requests_enabled   = true
  }

  tags = merge(local.tags,
    { Name = lower(format("ebs_apps-%s-%s-waf-acl", local.application_name, local.environment)) }
  )
}

resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = "/aws/wafv2/ebsapps"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("ebs_apps-%s-%s-waf-log-group", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "ebsapps_waf_logging" {
  resource_arn            = aws_wafv2_web_acl.ebsapps_waf_acl.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

resource "aws_wafv2_web_acl_association" "ebsapps_waf_alb" {
  resource_arn = aws_lb.ebsapps_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.ebsapps_waf_acl.arn
}

output "waf_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.ebsapps_waf_acl.id
}

output "waf_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.ebsapps_waf_acl.arn
}

output "waf_log_group_name" {
  description = "The name of the CloudWatch Log Group for WAF logs"
  value       = aws_cloudwatch_log_group.waf_log_group.name
}

output "regex_pattern_set_arn" {
  description = "The ARN of the regex pattern set for blocked paths"
  value       = aws_wafv2_regex_pattern_set.ebsapps_blocked_paths.arn
}
