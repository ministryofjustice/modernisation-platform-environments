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
      development-oasys-web = merge(local.webserver, { # merge common config and env specific
        tags = merge(local.webserver_tags, {
          oasys-environment = "t1"
        })
        # lb_target_groups = {
        #   http-8080 = {
        #     port                 = 8080
        #     protocol             = "HTTP"
        #     target_type          = "instance"
        #     deregistration_delay = 30
        #     health_check = {
        #       enabled             = true
        #       interval            = 30
        #       healthy_threshold   = 3
        #       matcher             = "200-399"
        #       path                = "/"
        #       port                = 8080
        #       timeout             = 5
        #       unhealthy_threshold = 5
        #     }
        #     stickiness = {
        #       enabled = true
        #       type    = "lb_cookie"
        #     }
        #   }
        # }
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
    }

    baseline_bastion_linux = {
      public_key_data = local.public_key_data.keys[local.environment]
      tags            = local.tags
    }
    baseline_lbs = {
      # AWS doesn't let us call it internal
      # private = {
      #   internal_lb              = true
      #   enable_delete_protection = false
      #   existing_target_groups   = local.existing_target_groups
      #   force_destroy_bucket     = true
      #   idle_timeout             = 3600
      #   public_subnets           = module.environment.subnets["private"].ids
      #   security_groups          = [aws_security_group.public.id]

      #   listeners = {
      #     development-oasys-web-http-8080 = merge(
      #       local.lb_web.http-8080, {
      #         replace = {
      #           target_group_name_replace     = "development-oasys-web"
      #           condition_host_header_replace = "development-oasys-web"
      #         }
      #     })
      #   }
      # }

      # public LB not needed right now
      # public = {
      #   internal_lb              = false
      #   enable_delete_protection = false
      #   force_destroy_bucket     = true
      #   idle_timeout             = 3600
      #   public_subnets           = module.environment.subnets["public"].ids
      #   security_groups          = [aws_security_group.public.id]
      # }
    }
  }
}
