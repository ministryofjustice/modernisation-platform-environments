#Variables
variable "env" { 
  description = "The target deployment environment (development, test, or production)."
  type        = string
  default     = "development"

  # Optional: Add a validation to ensure the input is one of the allowed values.
  validation {
    condition     = contains(["development", "test", "preproduction", "production"], var.env)
    error_message = "The environment must be one of 'development', 'test', 'preproduction', or 'production'."
  }
}
    
variable "region" {
    default = "eu-west-2"
}

variable "scope"{
    default = "REGIONAL"
}

variable "rule_name" {
    default = "ebs-trusted-rule" 
}

data "archive_file" "waf_toggle_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Pull an existing WAF Rule Group and rules using a dynamic name.
data "aws_wafv2_web_acl" "waf_web_acl" {
  name  = "ebs_waf"
  scope = "REGIONAL"
}


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

#Create IAM Role and Policy for Lambda
# resource "aws_iam_role" "waf_lambda_role" {
#   name = "waf-toggle-role-${var.env}"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = { Service = "lambda.amazonaws.com" },
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# # Create IAM Role Policy for Lambda
# resource "aws_iam_role_policy" "waf_lambda_policy" {
#   name = "waf-toggle-policy-${var.env}"
#   role = aws_iam_role.waf_lambda_role.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       { Effect = "Allow",
#         Action = ["wafv2:GetWebACL","wafv2:UpdateWebACL"],
#         Resource = "*" },
#       { Effect = "Allow",
#         Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],
#         Resource = "*" }
#     ]
#   })
# }

data "aws_iam_role" "waf_lambda_test_role" {
  name = "ccms-ebs-switch-off-on-role-athfh3u1"
}


resource "aws_lambda_function" "waf_toggle" {
  function_name = "waf-toggle-${var.env}"
  role =  data.aws_iam_role.waf_lambda_test_role.arn
  # role          = aws_iam_role.waf_lambda_role.arn
  filename      = data.archive_file.waf_toggle_zip.output_path
  source_code_hash = data.archive_file.waf_toggle_zip.output_base64sha256
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  environment {
    variables = {
      SCOPE        = var.scope
      WEB_ACL_NAME = data.aws_wafv2_web_acl.waf_web_acl.name
      WEB_ACL_ID   = data.aws_wafv2_web_acl.waf_web_acl.id
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
<p>The service is unavailable from 19:00 to 07:00 UK time. Apologies for any inconvenience caused.</p>
</div></body></html>
EOT
    }
  }
}

# CloudWatch (EventBridge)Event Rules to trigger Lambda
resource "aws_cloudwatch_event_rule" "waf_allow_0700_uk" {
  name                         = "waf-allow-0700-${var.env}"
  schedule_expression          = "cron(15 23 ? * MON-SUN *)"
  description                  = "Set WAF rule to ALLOW at 07:00 UK daily"
}

resource "aws_cloudwatch_event_rule" "waf_block_1900_uk" {
  name                         = "waf-block-1900-${var.env}"
  schedule_expression          = "cron(00 23 ? * MON-SUN *)"
  description                  = "Set WAF rule to BLOCK at 19:00 UK daily"
}

# CloudWatch (EventBridge)Event targets to Lambda
resource "aws_cloudwatch_event_target" "waf_allow_target" {
  rule      = aws_cloudwatch_event_rule.waf_allow_0700_uk.name
  target_id = "Allow"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "ALLOW" })
}

resource "aws_cloudwatch_event_target" "waf_block_target" {
  rule      = aws_cloudwatch_event_rule.waf_block_1900_uk.name
  target_id = "Block"
  arn       = aws_lambda_function.waf_toggle.arn
  input     = jsonencode({ mode = "BLOCK" })
}



# allow Events to invoke the Lambda
resource "aws_lambda_permission" "waf_events_allow" {
  statement_id  = "AllowEvents0700-${var.env}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_allow_0700_uk.arn
}
resource "aws_lambda_permission" "waf_events_block" {
  statement_id  = "AllowEvents1900-${var.env}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_toggle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_block_1900_uk.arn
}