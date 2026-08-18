locals {
  file_dispatch_prefixes = {
    development = {
      # synergy = {
      #   "/" = {
      #     action = null
      #     notifications = {
      #       email = null
      #       slack = null
      #       teams = null
      #     }
      #   }
      #   "/pensions/" = {
      #     action        = null
      #     notifications = {}
      #   }
      #   "/routes/1/" = {
      #     action        = null
      #     notifications = {}
      #   }
      # }
      #
      # web_app = {
      #   "/group/group-1/" = {
      #     action        = null
      #     notifications = {}
      #   }
      # }
    }
    test          = {}
    preproduction = {}
    production    = {}
  }

  environment_file_dispatch_prefixes = merge(
    {},
    [
      for identity, prefixes in local.file_dispatch_prefixes[local.environment] : {
        for prefix, configuration in prefixes :
        "${identity}${prefix}" => configuration
      }
    ]...
  )
}