###############################################################################
# Cluster Components — Thin wrapper calling the shared module
###############################################################################

module "spoke_components" {
  source = "../../../modules/cp-spoke-components"

  cluster_name     = local.cluster_name
  vpc_id           = data.aws_vpc.selected.id
  is_production    = contains(local.mp_environments, terraform.workspace) ? "true" : "false"
  environment_name = terraform.workspace
  tags             = local.tags
}
