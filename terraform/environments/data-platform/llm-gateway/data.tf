data "aws_eks_cluster" "cluster" {
  name = "${local.application_name}-${local.environment}"
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}

data "aws_iam_openid_connect_provider" "cluster" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

data "aws_secretsmanager_secret_version" "cloud_platform_live" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = "cloud-platform/live"
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_namespace" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = tostring(module.cloud_platform_live_namespace_secret[0].secret_id)
}

data "aws_secretsmanager_secret_version" "litellm_license" {
  secret_id = module.litellm_license_secret.secret_id
}

data "aws_secretsmanager_secret_version" "litellm_entra_id" {
  secret_id = module.litellm_entra_id_secret.secret_id
}

data "aws_secretsmanager_secret_version" "justiceai_azure_openai" {
  secret_id = module.justiceai_azure_openai_secret.secret_id
}

data "aws_secretsmanager_secret_version" "azure_openai_secret" {
  secret_id = module.azure_openai_secret.secret_id
}

data "kubernetes_secret" "elasticache" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  provider = kubernetes.cloud_platform

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "elasticache"
  }
}

data "kubernetes_secret" "irsa" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  provider = kubernetes.cloud_platform

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "irsa"
  }
}

data "kubernetes_secret" "rds" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  provider = kubernetes.cloud_platform

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "rds"
  }
}
