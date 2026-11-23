locals {
  file_dispatch_prefixes = {
    development   = local.development
    test          = local.test
    preproduction = local.preproduction
    production    = local.production
  }

  # Keep Terraform-only pickup settings out of the runtime dispatch secret.
  dispatch_prefixes = {
    for identity, prefixes in local.file_dispatch_prefixes[var.environment] : identity => {
      for prefix, configuration in prefixes : prefix => {
        action        = configuration.action
        notifications = configuration.notifications
      }
    }
  }

  entries = merge({}, [
    for identity, prefixes in local.file_dispatch_prefixes[var.environment] : {
      for source_prefix, configuration in prefixes :
      "${identity}${source_prefix}" => {
        identity      = identity
        source_prefix = source_prefix
        name_suffix   = join("-", compact(split("/", "${identity}${source_prefix}")))
        action        = configuration.action
      }
    }
  ]...)

  pickup_entries = flatten([
    for identity, prefixes in local.file_dispatch_prefixes[var.environment] : [
      for source_prefix, configuration in prefixes : {
        prefix        = "${identity}${source_prefix}"
        notifications = configuration.notifications
        pickup        = configuration.pickup
      } if try(configuration.pickup, null) != null
    ]
  ])

  pickup_recipients = {
    for entry in local.pickup_entries : entry.pickup.recipient_id => {
      prefix            = entry.prefix
      authorised_groups = entry.pickup.authorised_groups
      slack_channel_id  = entry.pickup.slack_channel_id
      slack_team_id     = entry.pickup.slack_team_id
    }
  }
}
