resource "aws_cloudwatch_log_group" "waf_logs" {
  name               = "aws-waf-logs-${var.waf_name}" # must start with aws-waf-logs-
  retention_in_days  = 400
  kms_key_id         = var.kms_key_arn
  tags               = local.tags
}

data "aws_iam_policy_document" "waf_logging" {
  version = "2012-10-17"

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["wafv2.amazonaws.com"]
    }

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.waf_logs.arn}:*"
    ]

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

  resource_arn            = aws_wafv2_web_acl.waf[0].arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  depends_on = [aws_cloudwatch_log_resource_policy.waf_logs_policy]
}


#Must create log group in us-east-1
resource "aws_cloudwatch_log_group" "waf_logs_cf" {
  provider           = aws.us-east-1
  name               = "aws-waf-logs-${var.waf_name}-cf"
  retention_in_days  = 400
  kms_key_id         = var.multi_region_replica
  tags               = local.tags
}

resource "aws_cloudwatch_log_resource_policy" "waf_logs_policy_cf" {
  provider        = aws.us-east-1
  policy_name     = "waf-logs-policy-${var.waf_name}-cf"
  policy_document = data.aws_iam_policy_document.waf_logging.json
}

resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  count    = var.scope == "CLOUDFRONT" ? 1 : 0
  provider = aws.us-east-1

  resource_arn            = aws_wafv2_web_acl.cf[0].arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs_cf.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  depends_on = [aws_cloudwatch_log_resource_policy.waf_logs_policy_cf]
}

data "aws_caller_identity" "current" {}
