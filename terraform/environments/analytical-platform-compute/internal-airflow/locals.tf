locals {
  eks_cluster_name = "${local.application_name}-${local.environment}"

  create_internal_airflow = local.is-development
  
  mwaa_private_subnet_ids = [
    data.aws_subnet.apc_private_subnet_a.id,
    data.aws_subnet.apc_private_subnet_b.id
  ]

  /* Environment Configuration */
  environment_configuration = try(local.environment_configurations[local.environment], local.environment_configurations["development"])
}
