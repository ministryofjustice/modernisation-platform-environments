locals {
  /* VPC */
  our_vpc_name                                        = "${local.application_name}-${local.environment}"
  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.our_vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

  /* EKS */
  eks_cluster_name                           = "${local.application_name}-${local.environment}"
  eks_cloudwatch_log_group_name              = "/aws/eks/${local.eks_cluster_name}/logs"
  eks_cloudwatch_log_group_retention_in_days = 400

  /* Mapping Analytical Platform Environments to Modernisation Platform */

  environment_map = {
    "test"       = "development",
    "production" = "data-production"
  }
  analytical_platform_environment = format(
    "analytical-platform-%s",
    lookup(local.environment_map, local.environment, local.environment)
  )
  /* Environment Configuration */
  environment_configuration = local.environment_configurations[local.environment]
}

