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
      cwagent-oasys-autologoff = {
        retention_days = 90
      }
    }

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    autoscaling_groups = {
      webservers = merge(local.webserver, { # merge common config and env specific
        tags = merge(local.webserver_tags, {
          oasys-environment = "t1"
        })
        lb_target_groups = {
          http-8080 = {
            port                 = 8080
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 8080
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }
        }
      })

      development-oasys-db = merge(local.database, {
        tags = merge(local.database_tags, {
          oasys-environment = "development"
          server-type       = "oasys-db"
          description       = "Development OASys database"
          oracle-sids       = "OASPROD BIPINFRA"
          monitored         = true
        })
        ami_name = "oasys_oracle_db_*"
        # ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
      })
    }

    # Add database instances here. They will be created using ec2-database.tf
    databases = {
      # development-oasys-db-1 = {
      #   tags = {
      #     oasys-environment = "development"
      #     server-type       = "oasys-db"
      #     description       = "Development OASys database"
      #     oracle-sids       = "OASPROD BIPINFRA"
      #     monitored         = true
      #   }
      #   ami_name = "oasys_oracle_db_*"
      #   # ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
      #   instance = {
      #     instance_type             = "r6i.2xlarge"
      #     disable_api_termination   = true
      #     metadata_endpoint_enabled = "enabled"
      #   }
      #   # ebs_volumes = {
      #   #   "/dev/sdb" = { size = 100 }
      #   #   "/dev/sdc" = { size = 100 }
      #   # }
      #   # ebs_volume_config = {
      #   #   data  = { total_size = 200 }
      #   #   flash = { total_size = 50 }
      #   # }
      # }

      # dev-onr-db-1 = {
      #   tags = {
      #     oasys-environment = "development"
      #     server-type       = "onr-db"
      #     description       = "Development ONR database"
      #     oracle-sids       = "onrbods ONRAUD ONRSYS MISTRANS OASYSREP"
      #     monitored         = true
      #   }
      #   ami_name = "onr_oracle_db_*"
      #   instance = {
      #     instance_type             = "r6i.xlarge"
      #     disable_api_termination   = true
      #     metadata_endpoint_enabled = "enabled"
      #   }
      #   ebs_volumes = {
      #     "/dev/sdb" = { size = 100 }
      #     "/dev/sdc" = { size = 5120 }
      #   }
      #   ebs_volume_config = {
      #     data  = { total_size = 4000 }
      #     flash = { total_size = 1000 }
      #   }
      # }
    }

    baseline_bastion_linux = {
      public_key_data = local.public_key_data.keys[local.environment]
      tags            = local.tags
    }
  }
}

