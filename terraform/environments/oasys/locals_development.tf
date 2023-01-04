# oasys-development environment settings
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
      webservers = {
        ami_name = "oasys_webserver_*"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
        autoscaling_group = {
          desired_capacity = 1
        }
        autoscaling_schedules = {}
        subnet_name           = "webserver"
        tags = {
          server-type       = "webserver"
          description       = "Oasys webserver"
          nomis-environment = "t1"
        }
      }
    }
  }
}

