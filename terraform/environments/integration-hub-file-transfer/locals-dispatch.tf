locals {
  file_dispatch_prefixes = {
    development = {
      # example-transfer-identity = {
      #   "/" = {
      #     action = null
      #     notifications = {
      #       email = null # email address
      #       slack = null # slack webhook URL
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