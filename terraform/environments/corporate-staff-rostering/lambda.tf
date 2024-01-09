# START: lambda_cw_logs_xml_to_json

locals {
  lambda_cw_logs_xml_to_json = {
    monitored_log_group = "cwagent-windows-application"
    function_name       = "cw-logs-xml-to-json"
  }
}

module "lambda_cw_logs_xml_to_json" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function"

  application_name = local.lambda_cw_logs_xml_to_json.function_name
  function_name    = local.lambda_cw_logs_xml_to_json.function_name
  role_name        = local.lambda_cw_logs_xml_to_json.function_name

  package_type     = "Zip"
  filename         = "${path.module}/lambda/cw-xml-to-json/deployment_package.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/cw-xml-to-json/deployment_package.zip")
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"

  policy_json_attached = true
  policy_json = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })

  allowed_triggers = {
    AllowExecutionFromCloudWatch = {
      principal  = "logs.amazonaws.com"
      source_arn = "${module.baseline.cloudwatch_log_groups[local.lambda_cw_logs_xml_to_json.monitored_log_group].arn}:*"
    }
  }

  tags = {}
}

resource "aws_cloudwatch_log_subscription_filter" "cw_logs_xml_to_json" {
  name            = "cw-logs-xml-to-json"
  log_group_name  = local.lambda_cw_logs_xml_to_json.monitored_log_group
  destination_arn = module.lambda_cw_logs_xml_to_json.lambda_function_arn
}

# END: lambda_cw_logs_xml_to_json
