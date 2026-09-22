output "prefixes" {
  description = "File dispatch configuration grouped by transfer identity and source prefix."
  value       = local.file_dispatch_prefixes[var.environment]
}

output "entries" {
  description = "File dispatch entries keyed by a stable identifier for resource iteration."
  value       = local.entries
}