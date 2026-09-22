locals {
  file_dispatch_prefixes = {
    development = {
      dms1981 = {
        "/" = {
          action = null
          notifications = {
            email = null
            slack = null
            teams = null
          }
        }
        "/example/subdirectory/" = {
          action = null
          notifications = {
            email = null
            slack = null
            teams = null
          }
        }
      }
    }
    test          = {}
    preproduction = {}
    production    = {}
  }

  entries = merge([
    for identity, prefixes in local.file_dispatch_prefixes[var.environment] : {
      for source_prefix, configuration in prefixes :
      substr(sha256("${identity}:${source_prefix}"), 0, 12) => {
        identity      = identity
        source_prefix = source_prefix
        action        = configuration.action
      }
    }
  ]...)
}