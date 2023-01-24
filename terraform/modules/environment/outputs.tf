output "access" {
  description = "map of access elements found in the environments file json, e.g. nomis.json.  Map keys include github_slug, level, nuke"
  value       = local.environments_access[var.environment]
}

output "tags" {
  description = "map of default tags populated from environments file (application, business-unit, infrastructure-support, owner) and input variables (environment-name, source-code and is-production)"
  value       = local.tags
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

output "kms_keys" {
  description = "a map of business unit customer-managed keys where the map key is the prefix name, e.g. general, ebs, rds"
  value       = data.aws_kms_key.this
}
