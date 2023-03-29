# oasys-development environment specific settings
locals {
  development_config = {

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

    autoscaling_groups = { # currently this does nothing - add to baseline


      # development-oasys-db = merge(local.database, {
      #   tags = merge(local.database_tags, {
      #     oasys-environment = "development"
      #     server-type       = "oasys-db"
      #     description       = "Development OASys database"
      #     oracle-sids       = "OASPROD BIPINFRA"
      #     monitored         = true
      #   })
      #   ami_name = "oasys_oracle_db_*"
      #   # ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
      # })
    }

    # Add database instances here. They will be created using ec2-database.tf
    databases = { # currently this does nothing - add to baseline
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
      # public_key_data = local.public_key_data.keys[local.environment]
      # tags            = local.tags
    }


    baseline_s3_buckets = {

      # the shared image builder bucket is just created in development
      oasys-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_ec2_instances = {

      # Example instance using RedHat image with ansible provisioning
      # dev-redhat-rhel79-1 = {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name  = "RHEL-7.9_HVM-*"
      #     ami_owner = "309956199498"
      #   })
      #   instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      #     vpc_security_group_ids = ["private"]
      #   })
      #   user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      #   tags = {
      #     description = "For testing with official RedHat RHEL7.9 image"
      #     os-type     = "Linux"
      #     component   = "test"
      #     server-type = "set me to the ansible server type group vars"
      #   }
      # }

      # Example instance using base image with ansible provisioning
      # dev-base-rhel79-1 = {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name = "base_rhel_7_9_*"
      #   })
      #   instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      #     vpc_security_group_ids = ["private"]
      #   })
      #   user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      #   tags = {
      #     description = "For testing with official RedHat RHEL7.9 image"
      #     os-type     = "Linux"
      #     component   = "test"
      #     server-type = "set me to the ansible server type group vars"
      #   }
      # }
    }

    baseline_ec2_autoscaling_groups = {

      # Example ASG using base image with ansible provisioning
      # Include the autoscale-trigger-hook ansible role when using hooks
      development-oasys-web = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "oasys_webserver_*"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = {
          args = {
            lifecycle_hook_name  = "ready-hook"
            branch               = "main"
            ansible_repo         = "modernisation-platform-configuration-management"
            ansible_repo_basedir = "ansible"
            ansible_args         = ""
          }
          scripts = [
            "install-ssm-agent.sh.tftpl",
            "ansible-ec2provision.sh.tftpl",
            "post-ec2provision.sh.tftpl"
          ]
        }
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          os-type           = "Linux"
          oasys-environment = "t1"
          description       = "oasys webserver"
          component         = "web"
          server-type       = "oasys-web"
          os-version        = "RHEL 7.9"
        }

        # Example target group setup below

        # lb_target_groups = local.lb_target_groups
      }
    }

    baseline_lbs = {
      # AWS doesn't let us call it internal
    #   private = {
    #     internal_lb              = true
    #     enable_delete_protection = false
    #     existing_target_groups   = {
    #       development-oasys-web-http-8080 = local.lb_target_groups.http-8080
    #     }
    #     force_destroy_bucket     = true
    #     idle_timeout             = 3600
    #     public_subnets           = module.environment.subnets["private"].ids
    #     security_groups          = [aws_security_group.public.id]

    #     listeners = {
    #       development-oasys-web-http-8080 = {
    #         port     = 8080
    #         protocol = "HTTP"
    #         default_action = {
    #           type              = "forward"
    #           target_group_name = "development-oasys-web-http-8080"
    #         }
    #       }
    #     }

    #     # public LB not needed right now
    #     # public = {
    #     #   internal_lb              = false
    #     #   enable_delete_protection = false
    #     #   force_destroy_bucket     = true
    #     #   idle_timeout             = 3600
    #     #   public_subnets           = module.environment.subnets["public"].ids
    #     #   security_groups          = [aws_security_group.public.id]
    #     # }
    #   }
    }
  }
}


