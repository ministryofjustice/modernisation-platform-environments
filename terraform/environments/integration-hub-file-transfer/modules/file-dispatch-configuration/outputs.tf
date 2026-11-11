output "prefixes" {
  description = "File dispatch configuration grouped by transfer identity and source prefix."
  value       = local.dispatch_prefixes
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

output "pickup_recipients" {
  description = "Slack pickup destinations keyed by the stable recipient directory name."
  value       = local.pickup_recipients

  precondition {
    condition = alltrue([
      for entry in local.pickup_entries : entry.notifications.slack == entry.pickup.recipient_id
    ])
    error_message = "The Slack dispatch destination must match its pickup recipient ID."
  }
}
