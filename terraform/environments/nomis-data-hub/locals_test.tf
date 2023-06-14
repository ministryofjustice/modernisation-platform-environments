locals {
  test_config = {

    baseline_s3_buckets = {

      # the shared image builder bucket is just created in one account
      nomis-data-hub-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
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


      t1_ndh_app = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "nomis_data_hub_rhel_7_9_app_release_2023-05-02T00-00-47.783Z"
          ami_owner = "374269020027"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        tags = {
          description = "Standalone EC2 for testing RHEL7.9 NDH App"
          os-type     = "Linux"
          component   = "ndh"
          server-type = "ndh-app"
          monitored   = false
        }
      }

      t1_ndh_ems = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "nomis_data_hub_rhel_7_9_ems_test_2023-04-02T00-00-21.281Z"
          ami_owner = "374269020027"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        tags = {
          description = "Standalone EC2 for testing RHEL7.9 NDH App"
          os-type     = "Linux"
          component   = "ndh"
          server-type = "ndh-ems"
          monitored   = false
        }
      }
    }
    baseline_ec2_autoscaling_groups = {

      t1_ndh_app_a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "nomis_data_hub_rhel_7_9_app_release_2023-05-02T00-00-47.783Z"
          ami_owner = "374269020027"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Standalone EC2 for testing RHEL7.9 NDH App"
          os-type     = "Linux"
          component   = "ndh"
          server-type = "ndh-app"
          monitored   = false
        }
      }

      t1_ndh_ems_a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "nomis_data_hub_rhel_7_9_ems_test_2023-04-02T00-00-21.281Z"
          ami_owner = "374269020027"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Standalone EC2 for testing RHEL7.9 NDH ems"
          os-type     = "Linux"
          component   = "ndh"
          server-type = "ndh-ems"
          monitored   = false
        }
      }
      t1_ndh_jumpserver = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "nomis_windows_server_2022_jumpserver_release_*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/jumpserver-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-jumpserver"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 1 # set to 0 while testing
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 for ndh managment"
          os-type     = "Windows"
          component   = "jumpserver"
          server-type = "nomis-jumpserver"
        }
      }

      lb_target_groups = {
        http-7777 = {
          port                 = 7777
          protocol             = "HTTP"
          target_type          = "instance"
          deregistration_delay = 30
          health_check = {
            enabled             = true
            interval            = 30
            healthy_threshold   = 3
            matcher             = "200-399"
            path                = "/"
            port                = 7777
            timeout             = 5
            unhealthy_threshold = 5
          }
          stickiness = {
            enabled = true
            type    = "lb_cookie"
          }
        }
      }
    }
  }
}
