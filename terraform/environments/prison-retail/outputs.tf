output "acm_certificates_validation_records_external" {
  description = "ACM validation records for external zones"
  value       = { for key, value in module.baseline.acm_certificates : key => value.validation_records_external }
}

output "efs_dns_names" {
  description = "EFS DNS names"
  value       = { for key, value in module.baseline.efs : key => value.file_system.dns_name }
}

output "fsx_windows_dns_names" {
  description = "FSX Windows DNS Names"
  value       = { for key, value in module.baseline.fsx_windows : key => value.windows_file_system.dns_name }
}

output "route53_zone_ns_records" {
  description = "NS records of created zones"
  value       = { for key, value in module.baseline.route53_zones : key => value.name_servers }
}

output "s3_buckets" {
  description = "Names of created S3 buckets"
  value       = { for key, value in module.baseline.s3_buckets : key => value.bucket.id }
}
