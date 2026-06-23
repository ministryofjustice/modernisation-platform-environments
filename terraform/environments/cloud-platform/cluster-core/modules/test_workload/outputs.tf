output "namespace" {
  value       = var.name
  description = "Kubernetes namespace created for this workload."
}

output "hostname" {
  value       = var.hostname
  description = "Hostname this workload is exposed on."
}

output "waf_mode" {
  value       = var.create_waf_policy ? var.waf_rule_engine : "inherited-from-gateway"
  description = "Effective WAF mode for this workload (On / DetectionOnly / Off / inherited-from-gateway)."
}
