provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.cluster[0].endpoint, null)
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), null)
  token                  = try(data.aws_eks_cluster_auth.cluster[0].token, null)
}

provider "helm" {
  kubernetes = {
    host                   = try(data.aws_eks_cluster.cluster[0].endpoint, null)
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), null)
    token                  = try(data.aws_eks_cluster_auth.cluster[0].token, null)
  }
}

provider "kubectl" {
  host                   = try(data.aws_eks_cluster.cluster[0].endpoint, null)
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), null)
  token                  = try(data.aws_eks_cluster_auth.cluster[0].token, null)
  load_config_file       = false
}
