locals {
  litellm_master_key = "sk-${random_password.litellm_secret_key.result}" # "sk-" prefix is required by LiteLLM
}

resource "kubernetes_secret" "litellm_master_key" {
  metadata {
    namespace = "ai-gateway"
    name      = "litellm-master-key"
  }

  data = {
    master-key = local.litellm_master_key
  }

  type = "Opaque"
}
