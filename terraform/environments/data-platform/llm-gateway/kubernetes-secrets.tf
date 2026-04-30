locals {
  litellm_master_key = "sk-${random_password.litellm_secret_key.result}" # "sk-" prefix is required by LiteLLM
}

resource "kubernetes_secret" "litellm_master_key" {
  metadata {
    namespace = "llm-gateway"
    name      = "litellm-master-key"
  }

  data = {
    master-key = local.litellm_master_key
  }

  type = "Opaque"
}

resource "kubernetes_secret" "litellm_master_key_cloud_platform" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  provider = kubernetes.cloud_platform

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "litellm-master-key"
  }

  data = {
    master-key = local.litellm_master_key
  }

  type = "Opaque"
}

resource "kubernetes_secret" "litellm_license_cloud_platform" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  provider = kubernetes.cloud_platform

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "litellm-license"
  }

  data = {
    LITELLM_LICENSE = data.aws_secretsmanager_secret_version.litellm_license.secret_string
  }

  type = "Opaque"
}

resource "kubernetes_secret" "litellm_entra_id_cloud_platform" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  provider = kubernetes.cloud_platform

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "litellm-entra-id"
  }

  data = {
    MICROSOFT_CLIENT_ID     = jsondecode(data.aws_secretsmanager_secret_version.litellm_entra_id.secret_string)["client_id"]
    MICROSOFT_CLIENT_SECRET = jsondecode(data.aws_secretsmanager_secret_version.litellm_entra_id.secret_string)["client_secret"]
    MICROSOFT_TENANT        = jsondecode(data.aws_secretsmanager_secret_version.litellm_entra_id.secret_string)["tenant_id"]
    PROXY_ADMIN_ID          = jsondecode(data.aws_secretsmanager_secret_version.litellm_entra_id.secret_string)["proxy_admin_id"]
  }

  type = "Opaque"
}

resource "kubernetes_secret" "justiceai_azure_openai_cloud_platform" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  provider = kubernetes.cloud_platform

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "justiceai-azure-openai"
  }

  data = {
    JUSTICEAI_AZURE_OPENAI_API_BASE = jsondecode(data.aws_secretsmanager_secret_version.justiceai_azure_openai.secret_string)["api_base"]
    JUSTICEAI_AZURE_OPENAI_API_KEY  = jsondecode(data.aws_secretsmanager_secret_version.justiceai_azure_openai.secret_string)["api_key"]
  }

  type = "Opaque"
}

resource "kubernetes_secret" "azure_openai_cloud_platform" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  provider = kubernetes.cloud_platform

  metadata {
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    name      = "azure-openai"
  }

  data = {
    AZURE_OPENAI_API_BASE = jsondecode(data.aws_secretsmanager_secret_version.azure_openai_secret.secret_string)["api_base"]
    AZURE_OPENAI_API_KEY  = jsondecode(data.aws_secretsmanager_secret_version.azure_openai_secret.secret_string)["api_key"]
  }

  type = "Opaque"
}
