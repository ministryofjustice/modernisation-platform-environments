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
