resource "aws_route53_resolver_query_log_config" "connected_vpc" {
  name            = "connected-vpc"
  destination_arn = module.connected_vpc_route53_resolver_logs.cloudwatch_log_group_arn
}

resource "aws_route53_resolver_query_log_config_association" "connected_vpc" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.connected_vpc.id
  resource_id                  = module.connected_vpc.vpc_id
}

resource "aws_route53_resolver_query_log_config_association" "core_logging_s3_connected_vpc" {
  resolver_query_log_config_id = data.aws_route53_resolver_query_log_config.core_logging_s3.id
  resource_id                  = module.connected_vpc.vpc_id
}

resource "aws_route53_resolver_query_log_config_association" "core_logging_s3_isolated_vpc" {
  resolver_query_log_config_id = data.aws_route53_resolver_query_log_config.core_logging_s3.id
  resource_id                  = module.isolated_vpc.vpc_id
}
