resource "aws_route53_resolver_query_log_config_association" "core_logging_s3" {
  resolver_query_log_config_id = data.aws_route53_resolver_query_log_config.core_logging_s3.id
  resource_id                  = module.vpc.vpc_id
}
