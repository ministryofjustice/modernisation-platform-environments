data "aws_cloudwatch_event_source" "this" {
  count = local.is-production ? 1 : 0

  provider = aws.us-east-1

  name_prefix = local.auth0_event_source_name
}
