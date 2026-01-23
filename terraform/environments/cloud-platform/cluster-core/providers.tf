provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.cluster[0].endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), "")
  token                  = data.aws_eks_cluster_auth.cluster[0].token
}

provider "helm" {
  kubernetes = {
    host                   = try(data.aws_eks_cluster.cluster[0].endpoint, "")
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), "")
    token                  = data.aws_eks_cluster_auth.cluster[0].token
  }
}

provider "kubectl" {
  host                   = try(data.aws_eks_cluster.cluster[0].endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), "")
  token                  = data.aws_eks_cluster_auth.cluster[0].token
  load_config_file       = false
}
