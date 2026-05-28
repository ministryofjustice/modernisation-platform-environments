locals {
  litellm_master_key = "sk-${random_password.litellm_secret_key.result}" # "sk-" prefix is required by LiteLLM
}

resource "kubernetes_secret_v1" "litellm_master_key" {
  depends_on = [kubernetes_namespace_v1.ai_gateway]

  metadata {
    namespace = local.component_name
    name      = "litellm-master-key"
  }

  data = {
    master-key = local.litellm_master_key
  }

  type = "Opaque"
}
