output "gateway_name" {
  value = kubernetes_manifest.gateway.manifest.metadata.name
}

output "namespace" {
  value = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
}

output "service_name" {
  description = "Name of the Envoy Gateway data plane service that the ALB should target"
  value       = kubernetes_manifest.envoy_proxy.manifest.spec.provider.kubernetes.envoyService.name
}

output "service_port" {
  description = "Port of the Envoy Gateway service"
  value       = 80
}