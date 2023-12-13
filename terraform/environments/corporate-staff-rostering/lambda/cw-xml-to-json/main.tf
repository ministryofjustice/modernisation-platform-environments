resource "aws_ecr_repository" "cw_logs_xml_to_json" {
  name = "cw-logs-xml-to-json"
}

module "lambda_cw_logs_xml_to_json" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function"

  application_name = "cw-logs-xml-to-json"

  image_uri = "${aws_ecr_repostitory.cw_logs_xml_to_json.repository_url}:latest"

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

