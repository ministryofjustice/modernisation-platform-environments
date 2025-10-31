provider "kubernetes" {
  cluster_ca_certificate = try(base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["ca_certificate"]), null)
  host                   = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["cluster_endpoint"], null)
  token                  = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["token"], null)
}

provider "helm" {
  kubernetes = {
    cluster_ca_certificate = try(base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["ca_certificate"]), null)
    host                   = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["cluster_endpoint"], null)
    token                  = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["token"], null)
  }
}
