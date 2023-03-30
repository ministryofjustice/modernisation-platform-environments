output "route53_zone_ns_records" {
  description = "NS records of created zones"
  value       = { for key, value in module.baseline.route53_zones : key => value.name_servers }
}
