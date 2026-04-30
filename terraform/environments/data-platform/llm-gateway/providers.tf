provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "kubernetes" {
  alias = "cloud_platform"

  cluster_ca_certificate = try(base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["ca_certificate"]), null)
  host                   = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["cluster_endpoint"], null)
  token                  = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["token"], null)
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "helm" {
  alias = "cloud_platform"

  kubernetes = {
    cluster_ca_certificate = try(base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["ca_certificate"]), null)
    host                   = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["cluster_endpoint"], null)
    token                  = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["token"], null)
  }
}
