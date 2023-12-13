resource "aws_ecr_repository" "cw_logs_xml_to_json" {
  name = "cw-logs-xml-to-json"
}

module "lambda_cw_logs_xml_to_json" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function"

  application_name = "cw-logs-xml-to-json"

  image_uri = null # TODO add image uri

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
  name            = "cw-logs-xml-to-json-application-logs"
  log_group_name  = null # TODO add log group name
  filter_pattern  = ""   # TODO add filter pattern
  destination_arn = module.lambda_cw_logs_xml_to_json.lambda_function_arn
}
