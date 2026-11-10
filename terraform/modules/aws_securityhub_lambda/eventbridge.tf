resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  name        = "${var.project_name}-securityhub-findings-rule"
  description = "Send matching AWS Security Hub findings to the ${var.project_name} Lambda"

  event_pattern = jsonencode({
    source        = ["aws.securityhub"]
    "detail-type" = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = var.finding_severity_labels
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub_findings" {
  rule      = aws_cloudwatch_event_rule.securityhub_findings.name
  target_id = "${var.project_name}-target"
  arn       = aws_lambda_function.securityhub_finding_issue.arn

  depends_on = [aws_lambda_permission.securityhub_findings]
}

resource "aws_lambda_permission" "securityhub_findings" {
  statement_id   = "AllowSecurityHubEventBridge"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.securityhub_finding_issue.function_name
  principal      = "events.amazonaws.com"
  source_arn     = aws_cloudwatch_event_rule.securityhub_findings.arn
  source_account = var.aws_account_id
}

# To re-enable once rolled out as part of POC
# resource "aws_lambda_permission" "allow_external_securityhub_accounts_eventbridge" {
#   for_each = nonsensitive(toset(keys(local.securityhub_accounts)))
#
#   statement_id  = "AllowSecurityHubEvents${each.key}"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.securityhub_finding_issue.function_name
#   principal     = "arn:aws:iam::${local.securityhub_accounts[each.key]}:role/EventBridgeInvokeSecurityHubLambda"
# }
