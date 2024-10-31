resource "aws_route53_resolver_query_log_config" "mojo_debug" {
  name            = "mojio-debug"
  destination_arn = module.mojo_debug_logs.cloudwatch_log_group_arn
}

resource "aws_route53_resolver_query_log_config_association" "mojo_debug" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.mojo_debug.id
  resource_id                  = module.connected_vpc.vpc_id
}
