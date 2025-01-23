/*
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  count = var.scope != "CLOUDFRONT" ? 0 : 1
  log_destination_configs = [
    "arn:aws:firehose:us-east-1:123456789012:deliverystream/aws-waf-logs-default-ip-owasp-bots-datadog"
  ]
  provider     = aws.us-east-1
  resource_arn = aws_wafv2_web_acl.example.arn

  redacted_fields {
    single_header {
      name = "Authorization"
    }
    method {}
    query_string {}
    uri_path {}
  }

  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior    = "DROP"
      requirement = "MEETS_ALL"

      condition {
        action_condition {
          action = "ALLOW"
        }
      }
    }
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  count = var.scope != "CLOUDFRONT" ? 1 : 0
  log_destination_configs = [
    "arn:aws:firehose:us-east-1:123456789012:deliverystream/aws-waf-logs-default-ip-owasp-bots-datadog"
  ]

  resource_arn = aws_wafv2_web_acl.example.arn

  redacted_fields {
    single_header {
      name = "Authorization"
    }
    method {}
    query_string {}
    uri_path {}
  }

  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior    = "DROP"
      requirement = "MEETS_ALL"

      condition {
        action_condition {
          action = "ALLOW"
        }
      }
    }
  }
}
*/
