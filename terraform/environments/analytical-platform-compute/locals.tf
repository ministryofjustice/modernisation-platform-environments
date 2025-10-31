locals {

  # /* Mapping Analytical Platform Environments to Modernisation Platform */

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

  /* Private subnet arns */
  private_subnet_arns = [
    for subnet_id in data.aws_subnets.apc_private.ids :
    "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/${subnet_id}"
  ]
}
