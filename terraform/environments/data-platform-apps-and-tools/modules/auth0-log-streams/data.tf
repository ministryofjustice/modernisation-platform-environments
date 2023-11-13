# Current account data
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_cloudwatch_event_source" "this" {
  name_prefix = var.event_source_name
}