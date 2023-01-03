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

    ec2_test_autoscaling_groups = {
      # rhel-7-9-base = {
      #   tags = {
      #     description = "Standalone EC2 for testing RHEL7.9 base image"
      #     monitored   = false
      #   }
      #   ami_name = "oasys_rhel_7_9_baseimage*"
      #   # branch   = var.BRANCH_NAME # comment in if testing ansible
      # }
    }

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    webservers         = {}
    ec2_test_instances = {}
  }
}

