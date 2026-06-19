output "ingress_name" {
  description = "Name of the Ingress resource"
  value       = kubernetes_ingress_v1.envoy.metadata[0].name
}

output "ingress_namespace" {
  description = "Namespace of the Ingress resource"
  value       = kubernetes_ingress_v1.envoy.metadata[0].namespace
}

output "ingress_class_name" {
  description = "Name of the Ingress class"
  value       = kubernetes_ingress_class_v1.alb.metadata[0].name
}

output "alb_dns_name" {
  description = "DNS name of the ALB (available after provisioning)"
  value       = try(kubernetes_ingress_v1.envoy.status[0].load_balancer[0].ingress[0].hostname, null)
}
