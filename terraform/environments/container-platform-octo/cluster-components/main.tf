###############################################################################
# Container Platform OCTO — Cluster Components
#
# Thin wrapper calling the shared cluster-components module from cloud-platform.
###############################################################################

module "cluster_components" {
  source = "../../cloud-platform/modules/cluster-components"

  cluster_name     = local.cluster_name
  vpc_id           = data.aws_vpc.selected.id
  account_id       = data.aws_caller_identity.current.account_id
  is_production    = local.is-production ? "true" : "false"
  environment_name = terraform.workspace
  tags             = local.tags
}
