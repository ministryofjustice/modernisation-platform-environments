module "karpenter" {
  count   = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  source  = "github.com/ministryofjustice/container-platform-terraform-karpenter?ref=initial-module"

  cluster_name = local.cluster_name
  cluster_endpoint = module.eks[0].cluster_endpoint
}