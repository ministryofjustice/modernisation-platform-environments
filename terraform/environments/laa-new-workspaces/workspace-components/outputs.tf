##############################################
### Route53 Zone Name Servers
### For NS delegation in parent zone
##############################################
output "external_zone_name_servers" {
  description = "Name servers for external zone - add these as NS records in parent zone (core-network-services)"
  value       = aws_route53_zone.external.name_servers
}

output "external_zone_name" {
  description = "External zone name for NS delegation"
  value       = aws_route53_zone.external.name
}
