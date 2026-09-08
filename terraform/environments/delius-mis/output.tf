output "acm_certificates_validation_records_external_prod" {
  description = "ACM validation records for prod external zones"
  value       = local.is-production ? module.environment_production[0].acm_certificates_validation_records_external : null
}
