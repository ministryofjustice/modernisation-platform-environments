moved {
  from = module.aws_health_lambda_cloudwatch_events_development
  to   = module.aws_lambda_event_forwarding_development
}

moved {
  from = module.aws_health_lambda_cloudwatch_events_test
  to   = module.aws_lambda_event_forwarding_test
}
