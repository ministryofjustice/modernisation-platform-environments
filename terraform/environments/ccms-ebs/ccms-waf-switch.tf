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

variable "ssogen_rule_name" {
  default = "ssogen-waf-ip-set"
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
  source_code_hash = data.archive_file.waf_maintenance_zip.output_base64sha256
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
      TIME_FROM        = "21:30" # Optional - these are the defaults
      TIME_TO          = "07:00" # Optional - these are the defaults
    }
  }
}

resource "aws_lambda_function" "ssogen_waf_maintenance" {
  count = local.is-development || local.is-test ? 1 : 0
  function_name    = "ssogen-waf-maintenance-${local.environment}"
  source_code_hash = data.archive_file.waf_maintenance_zip.output_base64sha256
  role             = aws_iam_role.waf_lambda_role.arn
  filename         = data.archive_file.waf_maintenance_zip.output_path
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  environment {
    variables = {
      SCOPE            = var.scope
      WEB_ACL_NAME     = aws_wafv2_web_acl.ssogen_web_acl[count.index].name
      WEB_ACL_ID       = aws_wafv2_web_acl.ssogen_web_acl[count.index].id
      RULE_NAME        = var.ssogen_rule_name
      CUSTOM_BODY_NAME = "maintenance_html"
      TIME_FROM        = "21:30" # Optional - these are the defaults
      TIME_TO          = "07:00" # Optional - these are the defaults
    }
  }
}

# EventBridge schedule to trigger Lambda
resource "aws_scheduler_schedule" "waf_allow_schedule" {
  name       = "waf-allow-schedule"
  group_name = "default"

  schedule_expression_timezone = "Europe/London"
  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(00 07 ? * MON-SUN *)"

  target {
    arn      = aws_lambda_function.waf_maintenance.arn
    input    = jsonencode({ mode = "ALLOW" })
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn
  }
}

resource "aws_scheduler_schedule" "waf_block_schedule" {
  name       = "waf-block-schedule"
  group_name = "default"

  schedule_expression_timezone = "Europe/London"
  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(30 21 ? * MON-SUN *)"

  target {
    arn      = aws_lambda_function.waf_maintenance.arn
    input    = jsonencode({ mode = "BLOCK" })
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn
  }
}

# IAM Role and Policy for Scheduler to invoke Lambda Functions
resource "aws_iam_role" "scheduler_invoke_lambda_role" {
  name = "scheduler-invoke-lambda-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "scheduler.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-scheduler-invoke-lambda-function-role"
    }
  )
}

# IAM Policy to allow Scheduler to invoke Lambda
resource "aws_iam_policy" "scheduler_invoke_lambda" {
  name = "scheduler-invoke-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "lambda:InvokeFunction",
      Resource = [
        aws_lambda_function.waf_maintenance.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_lambda_attachment" {
  role       = aws_iam_role.scheduler_invoke_lambda_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_lambda.arn
}
