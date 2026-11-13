# Central event bus (eu-west-2)
resource "aws_cloudwatch_event_bus" "securityhub_central" {
  name = local.securityhub_event_bus_name
}

data "aws_iam_policy_document" "securityhub_central_bus_policy" {
  statement {
    sid    = "AllowCoreAccountsPutEvents"
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]

    principals {
      type        = "AWS"
      identifiers = [for id in local.securityhub_source_account_ids : "arn:aws:iam::${id}:root"]
    }

    resources = [aws_cloudwatch_event_bus.securityhub_central.arn]
  }
}

resource "aws_cloudwatch_event_bus_policy" "securityhub_central" {
  event_bus_name = aws_cloudwatch_event_bus.securityhub_central.name
  policy         = data.aws_iam_policy_document.securityhub_central_bus_policy.json
}

resource "aws_cloudwatch_event_rule" "securityhub_new_high_critical" {
  name           = "securityhub-new-high-critical-to-logs"
  event_bus_name = aws_cloudwatch_event_bus.securityhub_central.name
  description    = "Routes NEW HIGH/CRITICAL Security Hub findings from core accounts into the metric ingester Lambda."

  event_pattern = jsonencode({
    "source" : ["aws.securityhub"],
    "detail-type" : ["Security Hub Findings - Imported"],
    "detail" : {
      "findings" : {
        "Severity" : { "Label" : ["HIGH", "CRITICAL"] },
        "Workflow" : { "Status" : ["NEW"] }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub_to_metrics" {
  rule           = aws_cloudwatch_event_rule.securityhub_new_high_critical.name
  event_bus_name = aws_cloudwatch_event_bus.securityhub_central.name
  target_id      = "SecurityHubMetricIngester"
  arn            = module.securityhub_metric_ingester.lambda_function_arn
}
