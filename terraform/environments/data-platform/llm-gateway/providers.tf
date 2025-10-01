provider "kubernetes" {
  cluster_ca_certificate = base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["ca_certificate"])
  host                   = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["cluster_endpoint"]
  token                  = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["token"]
}

provider "helm" {
  kubernetes = {
    cluster_ca_certificate = base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["ca_certificate"])
    host                   = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["cluster_endpoint"]
    token                  = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["token"]
  }
}
