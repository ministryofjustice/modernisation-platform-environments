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
          https = {
            port                 = 443
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 443
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
      # test = { # minimum config
      #   ami_name              = "base_rhel_7_9_*"
      #   autoscaling_schedules = {}
      #   instance = {
      #     disable_api_termination = false
      #     instance_type           = "t3.large"
      #     key_name                = aws_key_pair.ec2-user.key_name
      #     vpc_security_group_ids  = [aws_security_group.webserver.id]
      #   }
      #   autoscaling_group = {
      #     desired_capacity = 1
      #     max_size         = 1
      #     min_size         = 1
      #   }
      #   iam_resource_names_prefix = "oasys-test"
      #   tags = {
      #     oasys-environment = "t1"
      #     description       = "test"
      #     component         = "web"
      #     server-type       = "webserver"
      #   }
      # }
    }

    # these could be useful later when making the db
    # db_enabled                             = false
    # db_auto_minor_version_upgrade          = "true"
    # db_allow_major_version_upgrade         = "false"
    # db_backup_window                       = "03:00-06:00"
    # db_retention_period                    = "15"
    # db_maintenance_window                  = "mon:00:00-mon:03:00"
    # db_instance_class                      = "db.t3.small"
    # db_user                                = "eor"
    # db_allocated_storage                   = "500"
    # db_max_allocated_storage               = "0"
    # db_multi_az                            = "false"
    # db_iam_database_authentication_enabled = "false"
    # db_monitoring_interval                 = "0"
    # db_enabled_cloudwatch_logs_exports     = ["audit", "audit", "listener", "trace"]
    # db_performance_insights_enabled        = "false"
    # db_skip_final_snapshot                 = "true"

    # Add database instances here. They will be created using ec2-database.tf
    databases = {
      development-oasys-db-1 = {
        tags = {
          oasys-environment = "development"
          server-type       = "oasys-db"
          description       = "Development OASys database"
          oracle-sids       = "OASPROD BIPINFRA"
          monitored         = true
        }
        ami_name = "oasys_oracle_db_release_2023-02-14T09-53-15.859Z"
        # ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          instance_type             = "r6i.2xlarge"
          disable_api_termination   = true
          metadata_endpoint_enabled = "enabled"
        }
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }
          "/dev/sdc" = { size = 5120 }
        }
        ebs_volume_config = {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        }
      }

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
  }
}

