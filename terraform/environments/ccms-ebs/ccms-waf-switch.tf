#Environment variable come from Platform local file
locals {
  env = "data-${local.environment}"
}

variable "scope" {
  default = "REGIONAL"
}

variable "rule_name" {
  default = "ebs-trusted-rule"
}

data "archive_file" "waf_toggle_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/waf_lambda_function.py"
  output_path = "${path.module}/lambda/waf_lambda_function.zip"
}

# Pull an existing WAF Rule Group and rules using a dynamic name.
data "aws_wafv2_web_acl" "waf_web_acl" {
  name  = "ebs_waf"
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
  runtime          = "python3.11"
  timeout          = 30
  environment {
    variables = {
      SCOPE        = var.scope
      WEB_ACL_NAME = data.aws_wafv2_web_acl.waf_web_acl.name
      WEB_ACL_ID   = data.aws_wafv2_web_acl.waf_web_acl.id
      RULE_NAME    = var.rule_name

      # New variables for custom body injection
      CUSTOM_BODY_NAME = "maintenance_html"
      CUSTOM_BODY_HTML = <<EOT
<!doctype html><html lang="en"><head>
<meta charset="utf-8"><title>Maintenance</title>
<style>body{font-family:sans-serif;background:#0b1a2b;color:#fff;text-align:center;padding:4rem;}
.card{max-width:600px;margin:auto;background:#12243a;padding:2rem;border-radius:10px;}
</style></head><body><div class="card">
<h1>Scheduled Maintenance</h1>
<p>The service is unavailable from 19:00 to 07:00 UK time. Apologies for any inconvenience caused.</p>
</div></body></html>
EOT
    }
  }
}

// EventBridge scheduled rules to trigger Lambda
resource "aws_cloudwatch_event_rule" "waf_allow_0700_uk" {
  name                = "waf-allow-0700-${local.environment}"
  schedule_expression = "cron(00 07 ? * MON-SUN *)"
  description         = "Set WAF rule to ALLOW at 07:00 UK Tuesday to Sunday"
}

# The following Schedue is Thursady 30th Oct 2025 only
resource "aws_cloudwatch_event_rule" "waf_allow_0600_uk" {
  name                = "waf-allow-0700-${local.environment}"
  schedule_expression = "cron(00 06 ? * THU *)"
  description         = "Set WAF rule to ALLOW at 06:00 UK on Thursday-30-Oct-2025 only"
}

# The following Schedue is for Monday to Sunday at 19:00 UK time
resource "aws_cloudwatch_event_rule" "waf_block_1900_uk" {
  name                = "waf-block-1900-${local.environment}"
  schedule_expression = "cron(00 19 ? * MON-SUN *)"
  # schedule_expression = "cron(00 19 ? * TUE-SUN *)"
  description         = "Set WAF rule to BLOCK at 19:00 UK Monday to Sunday"
}

# The following schedule is for Monday at 22:00 UK time
# resource "aws_cloudwatch_event_rule" "waf_block_2200_uk" {
#   name                = "waf-block-2200-${local.environment}"
#   schedule_expression = "cron(00 22 ? * MON *)"
#   description         = "Set WAF rule to BLOCK at 22:00 UK on Monday-27-Oct-2025 only"
# }

resource "aws_cloudwatch_event_target" "waf_allow_target" {
  rule      = aws_cloudwatch_event_rule.waf_allow_0700_uk.name
  target_id = "AllowWAF"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "ALLOW" })
}

resource "aws_cloudwatch_event_target" "waf_block_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_1900_uk.name
  target_id = "BlockWAF"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}


# allow Events to invoke the Lambda
resource "aws_lambda_permission" "waf_events_allow" {
  statement_id  = "AllowEvents0700-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_allow_0700_uk.arn
}


resource "aws_lambda_permission" "waf_events_block" {
  statement_id  = "AllowEvents1900-${local.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_1900_uk.arn
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
  value       = aws_cloudwatch_event_rule.waf_block_1900_uk.arn
}

output "waf_block_rule_name" {
  description = "CloudWatch event rule name for block schedule"
  value       = aws_cloudwatch_event_rule.waf_block_1900_uk.name
}

output "waf_web_acl_full" {
  value = data.aws_wafv2_web_acl.waf_web_acl
}