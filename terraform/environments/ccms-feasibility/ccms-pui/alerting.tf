# Account alerts topic, managed by the alerting module in the ccms-feasibility root stack
data "aws_sns_topic" "alerts" {
  name = "${local.application_name}-alerts"
}
