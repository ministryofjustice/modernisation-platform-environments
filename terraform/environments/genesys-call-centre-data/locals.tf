#### This file can be used to store locals specific to the member account ####
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets    = cidrsubnets(local.application_data.accounts[local.environment].vpc_cidr, 4, 4, 4)

  /* EKS */
  eks_cluster_name                           = "${local.application_name}-${local.environment}"
  eks_cloudwatch_log_group_name              = "/aws/eks/${local.eks_cluster_name}/logs"
  eks_cloudwatch_log_group_retention_in_days = 400

  /* Environment Configuration */
  environment_configuration = local.environment_configurations[local.environment]
}
