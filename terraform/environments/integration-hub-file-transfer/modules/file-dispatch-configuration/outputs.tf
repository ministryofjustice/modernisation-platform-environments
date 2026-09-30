output "prefixes" {
  description = "File dispatch configuration grouped by transfer identity and source prefix."
  value       = local.file_dispatch_prefixes[var.environment]
}

output "entries" {
  description = "File dispatch entries keyed by transfer identity and source prefix."
  value       = local.entries

  precondition {
    condition = alltrue([
      for entry in values(local.entries) :
      can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", entry.name_suffix))
    ])
    error_message = "Dispatch identity and source prefix must produce a lowercase kebab-case resource name."
  }

  precondition {
    condition     = length(distinct([for entry in values(local.entries) : entry.name_suffix])) == length(local.entries)
    error_message = "Dispatch identity and source prefix must produce unique resource names."
  }
}