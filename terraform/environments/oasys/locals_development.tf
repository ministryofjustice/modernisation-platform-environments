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

    # autoscaling_groups = {
    #   webservers = merge(local.webserver, { # merge common config and env specific
    #     tags = {
    #       nomis-environment = "t1"
    #       description       = "oasys webserver"
    #       component         = "web"
    #       server-type       = "webserver"
    #     }
    #   })
    # }

    autoscaling_groups = {
      webservers = {
        ami_name = "oasys_webserver_*"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
        # server-type and nomis-environment auto set by module
        autoscaling_schedules = {}
        subnet_name           = "webserver"

        instance = {
          disable_api_termination      = false
          instance_type                = "t2.large"
          key_name                     = "ec2-user" #                                       aws_key_pair.ec2-user.key_name
          monitoring                   = true
          metadata_options_http_tokens = "optional"
          vpc_security_group_ids       = []       #[aws_security_group.webserver.id]
        }

        user_data_cloud_init = {
          args = {
            lifecycle_hook_name = "ready-hook"
          }
          scripts = [ # it would make sense to have these templates in a common area 
            "ansible-ec2provision.sh.tftpl",
            "post-ec2provision.sh.tftpl"
          ]
          write_files = {}
        }

        ssm_parameters_prefix     = "webserver/"
        iam_resource_names_prefix = "ec2-webserver-asg"

        autoscaling_group = {
          desired_capacity = 1
          max_size         = 2
          min_size         = 0

          health_check_grace_period = 300
          health_check_type         = "ELB"
          force_delete              = true
          termination_policies      = ["OldestInstance"]
          target_group_arns         = [] # TODO
          vpc_zone_identifier       = ["vpc-01d7a2da8f9f1dfec"] #data.aws_subnets.private.ids
          wait_for_capacity_timeout = 0

          # this hook is triggered by the post-ec2provision.sh
          initial_lifecycle_hooks = {
            "ready-hook" = {
              default_result       = "ABANDON"
              heartbeat_timeout    = 7200 # on a good day it takes 30 mins, but can be much longer
              lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
            }
          }
          warm_pool = {
            reuse_on_scale_in           = true
            max_group_prepared_capacity = 1
          }

          instance_refresh = {
            strategy               = "Rolling"
            min_healthy_percentage = 90 # seems that instances in the warm pool are included in the % health count so this needs to be set fairly high
            instance_warmup        = 300
          }
        }
      }
    }

  }
}

    