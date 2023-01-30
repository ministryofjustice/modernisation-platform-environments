output "access" {
  description = "map of access elements found in the environments file json, e.g. nomis.json.  Map keys include github_slug, level, nuke"
  value       = local.environments_access[var.environment]
}

output "tags" {
  description = "map of default tags populated from environments file (application, business-unit, infrastructure-support, owner) and input variables (environment-name, source-code and is-production)"
  value       = local.tags
}

output "availability_zones" {
  description = "availability zones for this account, see aws_availability_zones data object"
  value       = data.aws_availability_zones.this
}

output "vpc_name" {
  description = "name of vpc, e.g. hmpps-development"
  value       = local.vpc_name
}

output "vpc" {
  description = "shared aws_vpc resource"
  value       = data.aws_vpc.this
}

output "subnets" {
  description = "map of aws_subnets resources where the key is the subnet name, e.g. data, private, public"
  value       = data.aws_subnets.this
}

output "subnet" {
  description = "map of individual aws_subnet resources.  first map key is subnet name, second is zone name, e.g. subnet['private']['eu-west-2a']"
  value = {
    for subnet_name in local.subnet_names[var.subnet_set] : subnet_name => {
      for zone_name in data.aws_availability_zones.this.names : zone_name => data.aws_subnet.this["${subnet_name}-${zone_name}"]
    }
  }
}

output "domains" {
  description = "a map of public and internal domains, e.g. top-level modernisation platform, business unit specific, and application specific"
  value       = local.domains
}

output "route53_zones" {
  description = "a map of aws_route53_zone data objects where the key is the domain name"
  value       = merge(data.aws_route53_zone.core_network_services, data.aws_route53_zone.core_vpc)
}

output "kms_keys" {
  description = "a map of business unit customer-managed keys where the map key is the prefix name, e.g. general, ebs, rds"
  value       = data.aws_kms_key.this
}
