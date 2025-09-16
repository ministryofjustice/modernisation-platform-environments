# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# data "archive_file" "waf_toggle_zip" {
#   type        = "zip"
#   source_dir  = "${path.module}/lambda/lambda_function.py"
#   output_path = "${path.module}/lambda.zip"
# }


# data "aws_wafv2_web_acl" "ccms_ebs_waf_web_acl" {
#   name  = var.web_acl_name
#   scope = "REGIONAL"
# }

# resource "aws_iam_policy_document" "waf_lambda_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "waf_lambda_role" {
#   name               = "ccms-ebs-waf-lambda-role-${var.env}"
#   assume_role_policy = data.aws_iam_policy_document.waf_lambda_assume_role_policy.json
#   tags = {
#     Environment = var.env
#     Application = "ccms-ebs"
#     ManagedBy   = "Terraform"
#   }
# }

resource "aws_iam_role" "lambda_role" {
  name = "waf-toggle-role-${var.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "waf-toggle-policy-${var.env}"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow",
        Action = ["wafv2:GetWebACL","wafv2:UpdateWebACL"],
        Resource = "*" },
      { Effect = "Allow",
        Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],
        Resource = "*" }
    ]
  })
}

resource "aws_lambda_function" "waf_toggle" {
  function_name = "waf-toggle-${var.env}"
  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.waf_toggle_zip.output_path
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  environment {
    variables = {
      SCOPE        = var.scope
      WEB_ACL_NAME = var.web_acl_name
      WEB_ACL_ID   = data.aws_wafv2_web_acl.ccms_ebs_waf_web_acl.id
      RULE_NAME    = var.rule_name

        # New variables for custom body injection
      CUSTOM_BODY_NAME   = "maintenance_html"
      CUSTOM_BODY_HTML   = <<EOT
<!doctype html><html lang="en"><head>
<meta charset="utf-8"><title>Maintenance</title>
<style>body{font-family:sans-serif;background:#0b1a2b;color:#fff;text-align:center;padding:4rem;}
.card{max-width:600px;margin:auto;background:#12243a;padding:2rem;border-radius:10px;}
</style></head><body><div class="card">
<h1>Scheduled Maintenance</h1>
<p>The service is unavailable from 19:00 to 07:00 UK time.</p>
</div></body></html>
EOT
    }
  }
}

# CloudWatch Event Rules to trigger Lambda
resource "aws_cloudwatch_event_rule" "allow_0700_uk" {
  name                         = "waf-allow-0700-${var.env}"
  schedule_expression          = "cron(0 7 ? * MON-SUN *)"
  description                  = "Set WAF rule to ALLOW at 07:00 UK daily"
}

resource "aws_cloudwatch_event_rule" "block_1900_uk" {
  name                         = "waf-block-1900-${var.env}"
  schedule_expression          = "cron(0 19 ? * MON-SUN *)"
  description                  = "Set WAF rule to BLOCK at 19:00 UK daily"
}

resource "aws_cloudwatch_event_target" "allow_target" {
  rule      = aws_cloudwatch_event_rule.allow_0700_uk.name
  target_id = "Allow"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "ALLOW" })
}

resource "aws_cloudwatch_event_target" "block_target" {
  rule      = aws_cloudwatch_event_rule.block_1900_uk.name
  target_id = "Block"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}

# allow Events to invoke the Lambda
resource "aws_lambda_permission" "events_allow" {
  statement_id  = "AllowEvents0700-${var.env}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.lambda_function
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.allow_0700_uk.arn
}
resource "aws_lambda_permission" "events_block" {
  statement_id  = "AllowEvents1900-${var.env}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.lambda_function
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.block_1900_uk.arn
}

