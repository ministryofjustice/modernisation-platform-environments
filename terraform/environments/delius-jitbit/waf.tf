resource "aws_wafv2_web_acl" "this" {
  name        = "${local.application_name}-acl"
  description = "Web ACL for ${local.application_name}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      # Dont do anything but count requests that match the rules in the ruleset
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.application_name}-common-ruleset"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 1

    override_action {
      # Dont do anything but count requests that match the rules in the ruleset
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.application_name}-SQLi-ruleset"
      sampled_requests_enabled   = true
    }
  }

  tags = local.tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.application_name}-waf-metrics"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.external.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

resource "aws_cloudwatch_log_group" "example" {
  name = "aws-waf-logs-some-uniq-suffix"
}
resource "aws_wafv2_web_acl_logging_configuration" "example" {
  log_destination_configs = [aws_cloudwatch_log_group.example.arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
}
resource "aws_cloudwatch_log_resource_policy" "example" {
  policy_document = data.aws_iam_policy_document.example.json
  policy_name     = "webacl-policy-uniq-name"
}
data "aws_iam_policy_document" "example" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "AWS"
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.example.arn}:*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "aws:SourceArn"
    }
    condition {
      test     = "StringEquals"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
      variable = "aws:SourceAccount"
    }
  }
}
