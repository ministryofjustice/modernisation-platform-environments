module "karpenter" {
  count   = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  source  = "github.com/ministryofjustice/container-platform-terraform-karpenter?ref=74ef416c6d9bc07f2a59445b078d8eb851b7fdfc" #0.1.1
  cluster_name = local.cluster_name
  cluster_endpoint = module.eks[0].cluster_endpoint
  k8s_version = local.environment_configuration.eks_cluster_version

  depends_on = [ module.eks ]
}
