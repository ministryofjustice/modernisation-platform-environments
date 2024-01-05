# START: lambda_cw_logs_xml_to_json

module "lambda_cw_logs_xml_to_json" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function"

  application_name = "cw-logs-xml-to-json"
  function_name    = "cw-logs-xml-to-json"
  role_name        = "cw-logs-xml-to-json"

  package_type     = "Zip"
  filename         = "${path.module}/lambda/cw-xml-to-json/deployment_package.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/cw-xml-to-json/deployment_package.zip")
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"

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

  tags = {}
}

resource "aws_cloudwatch_log_subscription_filter" "cw_logs_xml_to_json" {
  for_each = {
    "iwfm-scheduler" = {
      pattern = "%iWFM Scheduler.+service started%"
    },
  }

  name            = "cw-logs-xml-to-json-${each.key}"
  log_group_name  = "cwagent-windows-application"
  filter_pattern  = each.value.pattern
  destination_arn = module.lambda_cw_logs_xml_to_json.lambda_function_arn
}

# END: lambda_cw_logs_xml_to_json
