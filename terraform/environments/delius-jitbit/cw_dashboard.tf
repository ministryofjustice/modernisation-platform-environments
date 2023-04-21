resource "aws_cloudwatch_dashboard" "jitbit" {
  dashboard_body = ""
  dashboard_name = local.application_name
}