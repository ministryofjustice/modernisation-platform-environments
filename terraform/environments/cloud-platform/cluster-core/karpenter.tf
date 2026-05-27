module "karpenter" {
  count  = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  source = "github.com/ministryofjustice/container-platform-terraform-karpenter?ref=5028eb32e7fa4386a879a47307620eecfb41fe63" #0.1.0

  cluster_name     = local.cluster_name
  cluster_endpoint = data.aws_eks_cluster.cluster[0].endpoint
  k8s_version      = data.aws_eks_cluster.cluster[0].version
}