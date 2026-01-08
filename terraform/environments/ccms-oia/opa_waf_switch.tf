#Environment variable come from Platform local file
locals {
  env = "data-${local.environment}"
}

variable "scope" {
  default = "REGIONAL"
}

variable "rule_name" {
  default = "ccms-opa-waf-ip-set"
}

data "archive_file" "waf_toggle_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/waf_lambda_function.py"
  output_path = "${path.module}/lambda/waf_lambda_function.zip"
}

# Pull an existing WAF Rule Group and rules using a dynamic name.
data "aws_wafv2_web_acl" "waf_web_acl" {
  name  = "ccms-opa-web-acl"
  scope = "REGIONAL"
}


#Create IAM Role and Policy for Lambda
resource "aws_iam_role" "waf_lambda_role" {
  name = "waf-toggle-role-${local.environment}"
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
  name = "waf-toggle-policy-${local.environment}"
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

resource "aws_lambda_function" "waf_toggle" {
  function_name    = "waf-toggle-${local.environment}"
  role             = aws_iam_role.waf_lambda_role.arn
  filename         = data.archive_file.waf_toggle_zip.output_path
  source_code_hash = data.archive_file.waf_toggle_zip.output_base64sha256
  handler          = "waf_lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  environment {
    variables = {
      SCOPE            = var.scope
      WEB_ACL_NAME     = data.aws_wafv2_web_acl.waf_web_acl.name
      WEB_ACL_ID       = data.aws_wafv2_web_acl.waf_web_acl.id
      RULE_NAME        = var.rule_name
      CUSTOM_BODY_NAME = "maintenance_html"
      CUSTOM_BODY_HTML = <<EOT
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Maintenance</title>
<style>
body {
  font-family: sans-serif;
  background: #0b1a2b;
  color: #fff;
  text-align: center;
  padding: 4rem;
}
.card {
  max-width: 600px;
  margin: auto;
  background: #12243a;
  padding: 2rem;
  border-radius: 10px;
}
</style>
</head>
<body>
<div class="card">
  <h1>Service Offline</h1>
  <p><strong>CCMS is available from 07:00 to 21:30 UK time.It is not available on bank holidays.</strong></p>
</div>
</body>
</html>
EOT
    }
  }
}

// EventBridge scheduled rules Daily Monday-Sunday to trigger Lambda
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

# EventBridge rules for UK BankHolidays of 2026
# Block for 3rd April - Good Friday 
resource "aws_cloudwatch_event_rule" "waf_block_3apr26" {
  name                = "waf-block-3apr26-${local.environment}"
  schedule_expression = "cron(01 07 03 04 ? 2026)"
  description         = "Set WAF rule to BLOCK on Good Friday"
}

# Block for 6th April - Easter Monday
resource "aws_cloudwatch_event_rule" "waf_block_6apr26" {
  name                = "waf-block-6apr26-${local.environment}"
  schedule_expression = "cron(01 07 06 04 ? 2026)"
  description         = "Set WAF rule to BLOCK on Easter Monday"
}

# Block for 4th May - Early May Bank Holiday
resource "aws_cloudwatch_event_rule" "waf_block_4may26" {
  name                = "waf-block-4may26-${local.environment}"
  schedule_expression = "cron(01 07 04 05 ? 2026)"
  description         = "Set WAF rule to BLOCK on Early May Bank Holiday"
}

# Block for 25th May - Spring Bank Holiday
resource "aws_cloudwatch_event_rule" "waf_block_25may26" {
  name                = "waf-block-25may26-${local.environment}"
  schedule_expression = "cron(01 07 25 05 ? 2026)"
  description         = "Set WAF rule to BLOCK on Spring Bank Holiday"
}

# Block for 31st August - Summer Bank Holiday
resource "aws_cloudwatch_event_rule" "waf_block_31aug26" {
  name                = "waf-block-31aug26-${local.environment}"
  schedule_expression = "cron(01 07 31 08 ? 2026)"
  description         = "Set WAF rule to BLOCK on Summer Bank Holiday"
}

# Block for 25 Dec-Chirstmas Day
resource "aws_cloudwatch_event_rule" "waf_block_25dec26" {
  name                = "waf-block-25dec26-${local.environment}"
  schedule_expression = "cron(01 07 25 12 ? 2026)"
  description         = "Set WAF rule to BLOCK on 25th Dec Bank Holiday"
}

# Block for 28 Dec - Boxing day Substitute day
resource "aws_cloudwatch_event_rule" "waf_block_28dec26" {
  name                = "waf-block-28dec26-${local.environment}"
  schedule_expression = "cron(01 07 28 12 ? 2026)"
  description         = "Set WAF rule to BLOCK on 28th Dec Bank Holiday"
} 

# Block for 1 Jan
resource "aws_cloudwatch_event_rule" "waf_block_jan01" {
  name                = "waf-block-jan01-${local.environment}"
  schedule_expression = "cron(01 07 1 1 ? 2026)"
  description         = "Set WAF rule to BLOCK on Jan 1 (start)"
}



resource "aws_cloudwatch_event_target" "waf_allow_target" {
  rule      = aws_cloudwatch_event_rule.waf_allow_0700_uk.name
  target_id = "AllowWAF"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "ALLOW" })
}

resource "aws_cloudwatch_event_target" "waf_block_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_2130_uk.name
  target_id = "BlockWAF"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}

# Added the following targets for Bank Holidays
resource "aws_cloudwatch_event_target" "waf_block_3apr26_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_3apr26.name
  target_id = "BlockWAF3Apr26"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}

resource "aws_cloudwatch_event_target" "waf_block_6apr26_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_6apr26.name
  target_id = "BlockWAF6Apr26"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}

resource "aws_cloudwatch_event_target" "waf_block_4may26_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_4may26.name
  target_id = "BlockWAF4May26"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}

resource "aws_cloudwatch_event_target" "waf_block_25may26_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_25may26.name
  target_id = "BlockWAF25May26"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}

resource "aws_cloudwatch_event_target" "waf_block_31aug26_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_31aug26.name
  target_id = "BlockWAF31Aug26"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}

resource "aws_cloudwatch_event_target" "waf_block_25dec26_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_25dec26.name
  target_id = "BlockWAF25Dec26"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}

resource "aws_cloudwatch_event_target" "waf_block_28dec26_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_28dec26.name
  target_id = "BlockWAF28Dec26"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}

resource "aws_cloudwatch_event_target" "waf_block_jan01_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_jan01.name
  target_id = "BlockWAFJan01"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}

# allow Events to invoke the Lambda for Monday-Sunday schedules
resource "aws_lambda_permission" "waf_events_allow" {
  statement_id  = "AllowEvents0700-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_allow_0700_uk.arn
}

resource "aws_lambda_permission" "waf_events_block" {
  statement_id  = "BlockEvents2130-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_2130_uk.arn
}

# Allow events to invoke the Lambda for Bank Holidays
resource "aws_lambda_permission" "allow_eventbridge_block_3apr26" {
  statement_id  = "AllowEventBridgeBlock3Apr26-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_3apr26.arn
}
resource "aws_lambda_permission" "allow_eventbridge_block_6apr26" {
  statement_id  = "AllowEventBridgeBlock6Apr26-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_6apr26.arn
}
resource "aws_lambda_permission" "allow_eventbridge_block_4may26" {
  statement_id  = "AllowEventBridgeBlock4May26-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_4may26.arn
}
resource "aws_lambda_permission" "allow_eventbridge_block_25may26" {
  statement_id  = "AllowEventBridgeBlock25May26-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_25may26.arn
}
resource "aws_lambda_permission" "allow_eventbridge_block_31aug26" {
  statement_id  = "AllowEventBridgeBlock31Aug26-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_31aug26.arn
}
resource "aws_lambda_permission" "allow_eventbridge_block_25dec26" {
  statement_id  = "AllowEventBridgeBlock25Dec26-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_25dec26.arn
}
resource "aws_lambda_permission" "allow_eventbridge_block_28dec26" {
  statement_id  = "AllowEventBridgeBlockDec26-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_28dec26.arn
}
resource "aws_lambda_permission" "allow_eventbridge_block_jan01" {
  statement_id  = "AllowEventBridgeBlockJan01-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_jan01.arn
}
// Outputs
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
  value       = aws_lambda_function.waf_toggle.arn
}

output "waf_lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.waf_toggle.function_name
}