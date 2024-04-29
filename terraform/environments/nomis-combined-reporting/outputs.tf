output "efs_dns_names" {
  description = "EFS DNS names"
  value       = { for key, value in module.baseline.efs : key => value.file_system.dns_name }
}
output "route53_zone_ns_records" {
  description = "NS records of created zones"
  value       = { for key, value in module.baseline.route53_zones : key => value.name_servers }
}
