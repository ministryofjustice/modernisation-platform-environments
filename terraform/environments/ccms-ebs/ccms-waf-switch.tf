# Environment variable come from Platform local file
locals {
  env = "data-${local.environment}"
}

variable "scope" {
  default = "REGIONAL"
}

variable "rule_name" {
  default = "ebs-trusted-rule-ip-set"
}

data "archive_file" "waf_maintenance_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/waf_maintenance/lambda_function.py"
  output_path = "${path.module}/lambda/waf_maintenance/maintenance_lambda_function.zip"
}

# Pull an existing WAF Rule Group and rules using a dynamic name.
data "aws_wafv2_web_acl" "waf_web_acl" {
  name  = "ebs_internal_waf"
  scope = "REGIONAL"
}

# Create IAM Role and Policy for Lambda
resource "aws_iam_role" "waf_lambda_role" {
  name = "waf-maintenance-role-${local.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# Create IAM Role Policy for Lambda
resource "aws_iam_role_policy" "waf_lambda_policy" {
  name = "waf-maintenance-policy-${local.environment}"
  role = aws_iam_role.waf_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow",
        Action = ["wafv2:GetWebACL", "wafv2:UpdateWebACL"],
      Resource = "*" },
      { Effect = "Allow",
        Action = ["wafv2:GetRuleGroup"],
      Resource = "*" },
      { Effect = "Allow",
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      Resource = "*" }
    ]
  })
}

resource "aws_lambda_function" "waf_maintenance" {
  function_name    = "waf-maintenance-${local.environment}"
  source_code_hash = base64sha256(join("", local.lambda_source_hashes_payment_load_monitor))
  role             = aws_iam_role.waf_lambda_role.arn
  filename         = data.archive_file.waf_maintenance_zip.output_path
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  environment {
    variables = {
      SCOPE            = var.scope
      WEB_ACL_NAME     = data.aws_wafv2_web_acl.waf_web_acl.name
      WEB_ACL_ID       = data.aws_wafv2_web_acl.waf_web_acl.id
      RULE_NAME        = var.rule_name
      CUSTOM_BODY_NAME = "maintenance_html"
      TIME_FROM        = "21:30"  # Optional - these are the defaults
      TIME_TO          = "07:00"  # Optional - these are the defaults
    }
  }
}

# EventBridge scheduled rules to trigger Lambda
resource "aws_cloudwatch_event_rule" "waf_allow_0700_uk" {
  name                = "waf-allow-0700-${local.environment}"
  schedule_expression = "cron(00 07 ? * MON-SUN *)"
  description         = "Set WAF rule to ALLOW at 07:00 UK daily"
}

resource "aws_cloudwatch_event_rule" "waf_block_2130_uk" {
  name                = "waf-block-2130-${local.environment}"
  schedule_expression = "cron(30 21 ? * MON-SUN *)"
  description         = "Set WAF rule to BLOCK at 21:30 UK daily"
}

resource "aws_cloudwatch_event_target" "waf_allow_target" {
  rule      = aws_cloudwatch_event_rule.waf_allow_0700_uk.name
  target_id = "AllowWAF"
  arn       = aws_lambda_function.waf_maintenance.arn
  input     = jsonencode({ mode = "ALLOW" })
}

resource "aws_cloudwatch_event_target" "waf_block_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_2130_uk.name
  target_id = "BlockWAF"
  arn       = aws_lambda_function.waf_maintenance.arn
  input     = jsonencode({ mode = "BLOCK" })
}

# Allow Events to invoke the Lambda
resource "aws_lambda_permission" "waf_events_allow" {
  statement_id  = "AllowEvents0700-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_maintenance.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_allow_0700_uk.arn
}

resource "aws_lambda_permission" "waf_events_block" {
  statement_id  = "BlockEvents2130-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_maintenance.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_2130_uk.arn
}

# Outputs
output "waf_web_acl_name" {
  description = "WAF Web ACL name"
  value       = data.aws_wafv2_web_acl.waf_web_acl.name
}

output "waf_web_acl_id" {
  description = "WAF Web ACL id"
  value       = data.aws_wafv2_web_acl.waf_web_acl.id
}

output "waf_lambda_role_arn" {
  description = "IAM role ARN used by the Lambda"
  value       = aws_iam_role.waf_lambda_role.arn
}

output "waf_lambda_role_name" {
  description = "IAM role name used by the Lambda"
  value       = aws_iam_role.waf_lambda_role.name
}

output "waf_lambda_role_policy_id" {
  description = "IAM role inline policy id attached to Lambda role"
  value       = aws_iam_role_policy.waf_lambda_policy.id
}

output "waf_lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.waf_maintenance.arn
}

output "waf_lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.waf_maintenance.function_name
}

output "waf_allow_rule_arn" {
  description = "CloudWatch event rule ARN for allow schedule"
  value       = aws_cloudwatch_event_rule.waf_allow_0700_uk.arn
}

output "waf_allow_rule_name" {
  description = "CloudWatch event rule name for allow schedule"
  value       = aws_cloudwatch_event_rule.waf_allow_0700_uk.name
}

output "waf_block_rule_arn" {
  description = "CloudWatch event rule ARN for block schedule"
  value       = aws_cloudwatch_event_rule.waf_block_2130_uk.arn
}

output "waf_block_rule_name" {
  description = "CloudWatch event rule name for block schedule"
  value       = aws_cloudwatch_event_rule.waf_block_2130_uk.name
}

output "waf_web_acl_full" {
  value = data.aws_wafv2_web_acl.waf_web_acl
}