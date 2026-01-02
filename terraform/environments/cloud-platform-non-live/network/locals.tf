locals {
  /* VPC */
  # below are replaced for dev clusters
  cluster_environment = terraform.workspace # replaced with "development_cluster"
  cp_vpc_name         = "${local.application_name}-${local.environment}" # replaced with "cp-date-time"
  # end replacements
  cp_vpc_cidr = {
    development_cluster                   = "10.0.0.0/16"
    cloud-platform-non-live-test          = "10.1.0.0/16"
    cloud-platform-non-live-development   = "10.2.0.0/16"
    cloud-platform-non-live-preproduction = "10.3.0.0/16"
    cloud-platform-non-live-production    = "10.4.0.0/16"
  }
  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.cp_vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60
}
