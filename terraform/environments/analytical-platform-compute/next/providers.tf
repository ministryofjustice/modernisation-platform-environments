provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "bash"
    args        = ["../scripts/eks-authentication.sh", local.environment_management.account_ids[terraform.workspace], data.aws_eks_cluster.cluster.name]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "bash"
      args        = ["../scripts/eks-authentication.sh", local.environment_management.account_ids[terraform.workspace], data.aws_eks_cluster.cluster.name]
    }
  }
}
