provider "kubernetes" {
  host                   = module.eks[0].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks[0].cluster_name, "--region", "eu-west-2"]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks[0].cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks[0].cluster_name, "--region", "eu-west-2"]
    }
  }
}

provider "kubectl" {
  host                   = module.eks[0].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)
  apply_retry_count      = 10
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks[0].cluster_name, "--region", "eu-west-2"]
  }
  load_config_file = false
}
