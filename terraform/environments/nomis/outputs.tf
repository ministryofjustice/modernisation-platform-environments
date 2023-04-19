output "route53_zone_ns_records" {
  description = "NS records of created zones"
  value       = { for key, value in module.baseline.route53_zones : key => value.name_servers }
}

output "acm_certificates_validation_records_external" {
  description = "ACM validation records for external zones"
  value       = { for key, value in module.baseline.acm_certificates : key => value.validation_records_external }
}
