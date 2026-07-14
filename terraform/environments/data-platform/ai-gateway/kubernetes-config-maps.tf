resource "kubernetes_config_map_v1" "litellm_hooks" {
  metadata {
    namespace = module.ai_gateway_namespace.name
    name      = "litellm-hooks"
  }

  data = {
    "custom_callbacks.py" = file("${path.module}/src/litellm-hooks/custom_callbacks.py")
  }
}
