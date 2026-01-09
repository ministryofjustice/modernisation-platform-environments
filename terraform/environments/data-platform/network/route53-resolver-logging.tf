# resource "aws_route53_resolver_query_log_config" "cloudwatch" {
#   name            = "cloudwatch-logs"
#   destination_arn = module.route53_resolver_log_group.cloudwatch_log_group_arn
# }

# resource "aws_route53_resolver_query_log_config_association" "main" {
#   resolver_query_log_config_id = aws_route53_resolver_query_log_config.cloudwatch.id
#   resource_id                  = aws_vpc.main.id
# }
