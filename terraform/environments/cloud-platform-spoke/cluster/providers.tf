provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.cluster.endpoint, null)
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), null)
  token                  = try(data.aws_eks_cluster_auth.cluster.token, null)
}

provider "helm" {
  kubernetes {
    host                   = try(data.aws_eks_cluster.cluster.endpoint, null)
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), null)
    token                  = try(data.aws_eks_cluster_auth.cluster.token, null)
  }
}
