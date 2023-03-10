output "region" {
  description = "AWS region"
  value       = var.region
}

output "business_unit" {
  description = "name of business unit which is also used as part of the VPC name, e.g. hmpps"
  value       = var.business_unit
}

output "account_name" {
  description = "name of the application account / terraform workspace, e.g. nomis-test"
  value       = local.account_name
}

output "account_names" {
  description = "list of all accounts for ghte given application, e.g. ['nomis-development', 'nomis-test', 'nomis-preproduction', 'nomis-production']"
  value       = local.account_names
}

output "modernisation_platform_account_id" {
  description = "id of the modernisation platform account retrieved from local ssm parameter"
  value       = data.aws_ssm_parameter.modernisation_platform_account_id.value
}

output "account_id" {
  description = "id of the application account"
  value       = var.environment_management.account_ids[local.account_name]
}

output "application_name" {
  description = "name of application, e.g. nomis, oasys etc.."
  value       = var.application_name
}

output "environment" {
  description = "name of environment, e.g. development, test, preproduction, production"
  value       = var.environment
}

output "subnet_set" {
  description = "modernisation platform subnet set, e.g. general"
  value       = var.subnet_set
}

output "account_ids" {
  description = "account id map where the key is the account name and the value is the account id"
  value       = var.environment_management.account_ids
}

output "account_root_arns" {
  description = "account arn map where the key is the account name and the value is the account id"
  value       = { for name, id in var.environment_management.account_ids : name => "arn:aws:iam::${id}:root" }
}

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
  value       = nonsensitive(sensitive(data.aws_kms_key.this))
}
