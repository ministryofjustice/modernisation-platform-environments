output "shared_prototype_edge" {
  description = "Shared CloudFront and WAF hosting details for static AI prototypes."
  value       = module.shared-prototype-edge.hosting
}