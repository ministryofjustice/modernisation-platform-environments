data "aws_secretsmanager_secret_version" "cloud_platform_live" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = "cloud-platform/live"
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_namespace" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.cloud_platform_live_namespace_secret[0].secret_id
}

data "aws_secretsmanager_secret_version" "litellm_license" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.litellm_license_secret[0].secret_id
}

data "aws_secretsmanager_secret_version" "litellm_entra_id" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.litellm_entra_id_secret[0].secret_id
}

data "aws_secretsmanager_secret_version" "justiceai_azure_openai" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.justiceai_azure_openai_secret[0].secret_id
}

data "kubernetes_secret" "elasticache" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "elasticache"
  }
}

data "kubernetes_secret" "irsa" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "irsa"
  }
}

data "kubernetes_secret" "rds" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "rds"
  }
}
