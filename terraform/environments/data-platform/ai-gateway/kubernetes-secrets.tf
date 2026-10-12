resource "kubernetes_secret_v1" "openai_proxy" {
  count = local.openai_enabled ? 1 : 0

  metadata {
    namespace = module.ai_gateway_namespace.name
    name      = "openai-proxy"
  }

  data = {
    OPENAI_PROXY_API_KEY = "sk-${random_password.openai_proxy[0].result}"
  }

  type = "Opaque"
}

resource "kubernetes_config_map_v1" "openai_policy" {
  count = local.openai_enabled ? 1 : 0

  metadata {
    namespace = module.ai_gateway_namespace.name
    name      = "openai-policy"
  }

  data = {
    "openai_policy.py" = file("${path.module}/src/openai_policy.py")
  }
}

resource "kubernetes_secret_v1" "litellm_master_key" {
  metadata {
    namespace = module.ai_gateway_namespace.name
    name      = "litellm-master-key"
  }

  data = {
    master-key = local.litellm_master_key
  }

  type = "Opaque"
}

resource "kubernetes_config_map_v1" "google_application_credentials" {
  metadata {
    namespace = module.ai_gateway_namespace.name
    name      = "google-application-credentials"
  }

  data = {
    "credentials.json" = local.google_application_credentials
  }
}
