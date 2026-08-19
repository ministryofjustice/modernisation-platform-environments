locals {
  file_dispatch_secret_name_prefix = "${local.application_name}/file-dispatch/"

  file_dispatch_prefixes = {
    development = {
      # NB. When we create a secret, we set ignore_changes = true. This is because we don't want to expose secret information (e.g. webhooks) in code.
      # example-transfer-identity = {
      #   "/" = {
      #     operations = [
      #       {
      #         id     = "notify-consumer-a"
      #         action = "notify"
      #         value  = "sensitive action configuration"
      #       }
      #     ]
      #   }
      #   "/app-1/" = {
      #     operations = []
      #   }
      # }
      #
      # example-web-app-group = {
      #   "/group/group-name/" = {
      #     operations = [
      #       {
      #         id     = "send-to-consumer-a"
      #         action = "send-to-consumer"
      #         value  = "sensitive action configuration"
      #       }
      #     ]
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

  environment_file_dispatch_prefixes = [
    for identity, prefixes in local.file_dispatch_prefixes[local.environment] : {
      for prefix, configuration in prefixes :
      "${local.file_dispatch_secret_name_prefix}${identity}${prefix}" => configuration
    }
  ]
}