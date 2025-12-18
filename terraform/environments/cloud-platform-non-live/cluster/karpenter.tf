module "karpenter" {
  count   = contains(local.enabled_workspaces, local.environment) ? 1 : 0
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.0"

  cluster_name = module.eks[0].cluster_name

  tags = local.tags
}