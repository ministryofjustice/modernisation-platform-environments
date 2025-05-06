locals {
  route53_zone     = "compute.development.analytical-platform.service.justice.gov.uk"
  eks_cluster_name = "${local.application_name}-${local.environment}"

  /* Environment Configuration */
  environment_configuration = local.environment_configurations[local.environment]
}
