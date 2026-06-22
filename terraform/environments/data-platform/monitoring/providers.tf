# Kubernetes provider for managing resources in the Cloud Platform cluster
provider "kubernetes" {
  host                   = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["cluster_endpoint"], null)
  cluster_ca_certificate = try(base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["ca_certificate"]), null)
  token                  = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["token"], null)
}

# Helm provider for deploying charts to the Cloud Platform cluster
provider "helm" {
  kubernetes = {
    host                   = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["cluster_endpoint"], null)
    cluster_ca_certificate = try(base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["ca_certificate"]), null)
    token                  = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["token"], null)
  }
}
