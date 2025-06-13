output "moj_cidr" {
  value       = local.moj_cidr
  description = "MoJ Infrastructure cidrs: map(string)"
}

output "moj_cidrs" {
  value       = local.moj_cidrs
  description = "MoJ Infrastructure aggregate cidrs: map(list(string))"
}

output "mp_ip" {
  value       = local.mp_ip
  description = "Modernisation Platform ips: map(string)"
}

output "mp_ips" {
  value       = local.mp_ips
  description = "Modernisation Platform ips: map(list(string))"
}

output "mp_cidr" {
  value       = local.mp_cidr
  description = "Modernisation Platform cidrs: map(string)"
}

output "mp_cidrs" {
  value       = local.mp_cidrs
  description = "Modernisation Platform cidrs: map(list(string))"
}

output "active_directory_cidrs" {
  value       = local.active_directory_cidrs
  description = "Active Directory cidrs: map(list(string))"
}

output "azure_fixngo_ip" {
  value       = local.azure_fixngo_ip
  description = "Azure FixNGo ips: map(string)"
}

output "azure_fixngo_ips" {
  value       = local.azure_fixngo_ips
  description = "Azure FixNGo aggregate ips: map(list(string))"
}

output "azure_fixngo_cidr" {
  value       = local.azure_fixngo_cidr
  description = "Azure FixNGo cidrs: map(string)"
}

output "azure_fixngo_cidrs" {
  value       = local.azure_fixngo_cidrs
  description = "Azure FixNGo aggregate cidrs: map(list(string))"
}

output "external_cidrs" {
  value       = local.external_cidrs
  description = "External cidrs: map(list(string))"
}
