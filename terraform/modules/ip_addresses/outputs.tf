output "moj_cidr" {
  value       = local.moj_cidr
  description = "MoJ Infrastructure cidrs: map(string)"
}

output "moj_cidrs" {
  value       = local.moj_cidrs
  description = "MoJ Infrastructure aggregate cidrs: map(list(string))"
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

output "azure_nomisapi_cidr" {
  value       = local.azure_nomisapi_cidr
  description = "Azure Nomis API AKS cidrs: map(string)"
}

output "azure_nomisapi_cidrs" {
  value       = local.azure_nomisapi_cidrs
  description = "Azure Nomis API AKS aggregate cidrs: map(list(string))"
}

output "azure_studio_hosting_cidr" {
  value       = local.azure_studio_hosting_cidr
  description = "Azure Studio Hosting AKS cidrs: map(string)"
}

output "azure_studio_hosting_cidrs" {
  value       = local.azure_studio_hosting_cidrs
  description = "Azure Studio Hosting AKS aggregate cidrs: map(list(string))"
}
