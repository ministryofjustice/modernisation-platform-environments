locals {
  file_dispatch_prefixes = {
    development = {
      # NB. When we create a secret, we set ignore_changes = true. This is because we don't want to expose secret information (e.g. webhooks) in code.
      # example-transfer-identity = {
      #   "/" = {
      #     action = null
      #     notifications = {
      #       email = null # email address
      #       slack = null # slack channel ID
      #       teams = null # teams webhook URL
      #     }
      #   }
      #   "/app-1/" = {
      #     action        = null
      #     notifications = {}
      #   }
      #   "/app-2/1/" = {
      #     action        = null
      #     notifications = {}
      #   }
      # }
      #
      # example-web-app-group = {
      #   "/group/group-name/" = {
      #     action        = null
      #     notifications = {}
      #   }
      # }
      dms1981 = {
        "/" = {
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

  environment_file_dispatch_prefixes = [
    for identity, prefixes in local.file_dispatch_prefixes[local.environment] : {
      for prefix, configuration in prefixes :
      "${identity}${prefix}" => configuration
    }
  ]
}