provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.cluster.endpoint, null)
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), null)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = try(["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name], null)
    command     = "aws"
  }
}

provider "helm" {
  kubernetes = {
    host = try(module.eks[0].cluster_endpoint, null)
    # host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = try(base64decode(module.eks[0].cluster_certificate_authority_data), null)
    # cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = try(["eks", "get-token", "--cluster-name", module.eks[0].cluster_name], null)
      # args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    }
  }
}

provider "kubectl" {
  host = try(module.eks[0].cluster_endpoint, null)
  # host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = try(base64decode(module.eks[0].cluster_certificate_authority_data), null)
  # cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token            = try(data.aws_eks_cluster_auth.cluster[0].token, null)
  load_config_file = false
}
