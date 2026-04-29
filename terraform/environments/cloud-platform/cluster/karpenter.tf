module "karpenter" {
  count   = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  source  = "github.com/ministryofjustice/container-platform-terraform-karpenter?ref=initial-module"

  cluster_name = local.cluster_name
  cluster_endpoint = try(module.eks[0].cluster_endpoint, null)
  cluster_ca_certificate = try(base64decode(module.eks[0].cluster_certificate_authority_data), null)
  provider_token = try(data.aws_eks_cluster_auth.cluster[0].token, null)

  provider_endpoint = try(data.aws_eks_cluster.cluster.endpoint, null)
  provider_cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), null)
  provider_cluster_name = data.aws_eks_cluster.cluster.name

  
}