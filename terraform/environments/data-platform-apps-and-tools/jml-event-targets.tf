resource "aws_cloudwatch_event_target" "jml_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.jml_lambda_trigger.name
  target_id = "jml-lambda-trigger"
  arn       = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-jml-extract-lambda-ecr-repo:1.0.1"
}