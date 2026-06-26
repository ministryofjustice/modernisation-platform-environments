output "namespace" {
  value = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
}

output "gateway_name" {
  value = kubernetes_manifest.gateway.manifest.metadata.name
}
output "envoy_proxy_name" {
  value = kubernetes_manifest.envoy_proxy.manifest.metadata.name
}

output "gateway_class_name" {
  value = kubernetes_manifest.gateway_class.manifest.metadata.name
}