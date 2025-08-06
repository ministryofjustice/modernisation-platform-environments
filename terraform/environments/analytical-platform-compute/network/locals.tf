locals {
  /* VPC */
  our_vpc_name                                        = "${local.application_name}-${local.environment}"
  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.our_vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

  /* AMP */
  amp_workspace_alias                        = "${local.application_name}-${local.environment}"
  amp_cloudwatch_log_group_name              = "/aws/amp/${local.amp_workspace_alias}"
  amp_cloudwatch_log_group_retention_in_days = 400

  /* EKS */
  eks_cluster_name                           = "${local.application_name}-${local.environment}"
  eks_cloudwatch_log_group_name              = "/aws/eks/${local.eks_cluster_name}/logs"
  eks_cloudwatch_log_group_retention_in_days = 400

  /* Kube Prometheus Stack */
  prometheus_operator_crd_version = "v0.83.0"

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

  # fix for routes.tf unknown values in for_each
  route_table_ids_map = {
    for idx, id in module.vpc.private_route_table_ids :
    idx => id
  }
  # fix for data source
  route53_zone = local.environment_configurations[local.environment].route53_zone

}

