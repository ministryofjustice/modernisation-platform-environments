output "gateway_name" {
  value = kubernetes_manifest.gateway.manifest.metadata.name
}

output "namespace" {
  value = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
}

output "service_port" {
  description = "Port of the Envoy Gateway service"
  value       = 80
}