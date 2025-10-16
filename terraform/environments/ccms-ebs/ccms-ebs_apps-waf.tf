resource "aws_wafv2_regex_pattern_set" "ebsapps_blocked_paths" {
  name        = "ebs_apps-blocked-paths"
  description = "Blocked EBS /OA_HTML/ paths"
  scope       = "REGIONAL"

  regular_expression {
    regex_string = "^/OA_HTML/.*SyncServlet.*"
  }

  regular_expression {
    regex_string = "^/OA_HTML/CZ(ErrorPage|Info|InitializationErrorPage|Initialize)\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/Cfg(Launch|Sebl)\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/MySample39\\.jsp"
  }

  regular_expression {
    regex_string = "^/OA_HTML/configurator/(Decache|DisplayCXResult|UiServlet)"
  }

  regular_expression {
    regex_string = "^/OA_HTML/cz(Container|Embed|HeartBeat|JradHeartBeat|Summary)\\.jsp"
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ebs_apps-waf-patterns", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl" "ebsapps_waf_acl" {
  name        = "ebs_apps-waf-acl"
  description = "WAF ACL to block access to Oracle EBS /OA_HTML/ endpoints"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "block-ebs-oa_html-paths"
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
      metric_name                = "Block-EBS-OA_HTML-paths"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "EBS-Apps-WAF"
    sampled_requests_enabled   = true
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ebs_apps-waf-acl", local.application_name, local.environment)) }
  )
}

resource "aws_cloudwatch_log_group" "ebsapps_oa_html" {
  name              = "/aws/waf/ebsapps/oa_html"
  retention_in_days = local.is_production ? 90 : 30

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ebs_apps-waf", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "ebsapps_waf_logging" {
  resource_arn            = aws_wafv2_web_acl.ebsapps_waf_acl.arn
  log_destination_configs = [aws_cloudwatch_log_group.ebsapps_oa_html.arn]

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

output "ebs_apps_waf_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.ebsapps_waf_acl.id
}

output "ebs_apps_waf_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.ebsapps_waf_acl.arn
}

output "ebs_apps_waf_log_group_name" {
  description = "The name of the CloudWatch Log Group for WAF logs"
  value       = aws_cloudwatch_log_group.ebsapps_oa_html.name
}

output "ebs_apps_waf_regex_pattern_set_arn" {
  description = "The ARN of the regex pattern set for blocked paths"
  value       = aws_wafv2_regex_pattern_set.ebsapps_blocked_paths.arn
}
