locals {
  /* VPC */
  cp_vpc_name = "${local.application_name}-${local.environment}"
  cp_vpc_cidr = {
    cloud-platform-non-live-test = "10.1.0.0/16"
    cloud-platform-non-live-development = "10.2.0.0/16"
    cloud-platform-non-live-preproduction = "10.3.0.0/16"
    cloud-platform-non-live-production = "10.4.0.0/16"
  }
  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.cp_vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

}