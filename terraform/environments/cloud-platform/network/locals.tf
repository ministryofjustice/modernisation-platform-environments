locals {
  mp_environments = [
    "cloud-platform-development",
    "cloud-platform-preproduction",
    "cloud-platform-live",
  ]
  cluster_environment = contains(local.mp_environments, terraform.workspace) ? local.environment : "development_cluster"
  cp_vpc_name         = terraform.workspace

  vpc_cidr = {
    cloud-platform-development      = "10.195.32.0/20"
    cloud-platform-preproduction    = "10.195.16.0/20"
    cloud-platform-live             = "10.195.0.0/20"
    container-platform-octo-nonlive = "10.195.48.0/20"
    container-platform-octo-live    = "10.41.0.0/20"
  }

  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.cp_vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

}
