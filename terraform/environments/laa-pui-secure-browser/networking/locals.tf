locals {
  /* VPC Flow Logs */
  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = "${local.vpc_name}-secure-browser"
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60
}
