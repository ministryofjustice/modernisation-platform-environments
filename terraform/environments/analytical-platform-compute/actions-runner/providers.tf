# Provider for interacting with the EKS cluster
provider "kubernetes" {
  host                   = data.aws_eks_cluster.apc_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.apc_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.apc_cluster.token
}

# Provider for interacting with the EKS cluster using Helm
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.apc_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.apc_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.apc_cluster.token
  }
}
