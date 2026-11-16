provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.cluster.endpoint, null)
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), null)
  token                  = try(data.aws_eks_cluster_auth.cluster.token, null)
}

provider "helm" {
  kubernetes = {
    host                   = try(data.aws_eks_cluster.cluster.endpoint, null)
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), null)
    token                  = try(data.aws_eks_cluster_auth.cluster.token, null)
  }
}

provider "kubectl" {
  host                   = try(data.aws_eks_cluster.cluster.endpoint, null)
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), null)
  token                  = try(data.aws_eks_cluster_auth.cluster.token, null)
  load_config_file       = false
}

# Only needed to destroy per-cluster FGAC objects left in older dev cluster state; remove once none remain.
provider "opensearch" {
  url               = "https://${local.opensearch_endpoint}"
  aws_region        = "eu-west-2"
  sign_aws_requests = true
  healthcheck       = false
  sniff             = false
}