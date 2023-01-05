# oasys-development environment specific settings
locals {
  oasys_development = {

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 90
      }
      cwagent-var-log-messages = {
        retention_days = 30
      }
      cwagent-var-log-secure = {
        retention_days = 90
      }
      cwagent-nomis-autologoff = {
        retention_days = 90
      }
    }

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    autoscaling_groups = {
      webservers = merge(local.webserver, { # merge common config and env specific
        tags = {
          nomis-environment = "t1"
          description       = "oasys webserver"
          component         = "web"
          server-type       = "webserver"
        }
      })
    }

  }
}

    