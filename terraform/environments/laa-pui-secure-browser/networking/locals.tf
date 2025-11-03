locals {
  /* VPC Flow Logs */
  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = "${local.vpc_name}-secure-browser"
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

  /* WSSB Supported Azs */
  wssb_supported_zone_ids = ["euw2-az1", "euw2-az2"]

  azid_to_name = {
    for idx, zid in data.aws_availability_zones.available.zone_ids :
    zid => data.aws_availability_zones.available.names[idx]
  }

  wssb_supported_az_names = [
    for zid in local.wssb_supported_zone_ids : local.azid_to_name[zid]
  ]
}
