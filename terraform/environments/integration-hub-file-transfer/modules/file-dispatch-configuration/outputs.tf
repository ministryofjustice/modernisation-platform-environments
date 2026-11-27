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

  precondition {
    condition = alltrue([
      for destination in local.push_to_sftp_destinations :
      destination.destination_prefix == "" || (
        can(regex("^([^/\\\\\\x00-\\x1f\\x7f]+/)+$", destination.destination_prefix)) &&
        !contains(split("/", destination.destination_prefix), ".") &&
        !contains(split("/", destination.destination_prefix), "..")
      )
    ])
    error_message = "SFTP destination_prefix must be empty or a safe relative directory ending in '/'."
  }

  precondition {
    condition = alltrue([
      for destination in local.push_to_sftp_destinations :
      length(destination.destination_cidr_blocks) > 0 &&
      alltrue([
        for cidr in destination.destination_cidr_blocks :
        can(cidrnetmask(cidr)) ? cidrnetmask(cidr) != "0.0.0.0" : false
      ]) &&
      destination.port >= 1 &&
      destination.port <= 65535 &&
      floor(destination.port) == destination.port &&
      contains(["posix", "direct"], destination.write_mode) &&
      length(destination.host_public_keys) > 0
    ])
    error_message = "SFTP destinations require explicit non-/0 IPv4 CIDRs, a valid integer TCP port, write_mode ('posix' or 'direct') and trusted host_public_keys."
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
