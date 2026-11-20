provider "kubernetes" {
  host                   = local.is-production ? jsondecode(data.aws_secretsmanager_secret_version.cloud_platform.secret_string)["cluster_endpoint"] : null
  cluster_ca_certificate = local.is-production ? base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform.secret_string)["cluster_ca_certificate"]) : null
  token                  = local.is-production ? data.aws_secretsmanager_secret_version.cloud_platform_service_account[0].secret_string : null
}
