data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "/aws/waf/${var.waf_name}-logs"
  retention_in_days = 30

  tags = local.tags
}

data "aws_iam_policy_document" "waf_logging" {
  version = "2012-10-17"

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.waf_logs.arn}:*"
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "waf_logs_policy" {
  policy_name     = "waf-logs-policy-${var.waf_name}"
  policy_document = data.aws_iam_policy_document.waf_logging.json
}


resource "aws_wafv2_web_acl_logging_configuration" "regional" {
  count = var.scope != "CLOUDFRONT" ? 1 : 0

  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.waf[0].arn

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  depends_on = [
    aws_cloudwatch_log_resource_policy.waf_logs_policy
  ]
}

# must use us-east-1 provider for CloudFront WAF logging
resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  count    = var.scope == "CLOUDFRONT" ? 1 : 0
  provider = aws.us-east-1

  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.cf[0].arn

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  depends_on = [
    aws_cloudwatch_log_resource_policy.waf_logs_policy
  ]
}















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
