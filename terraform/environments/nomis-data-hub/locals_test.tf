locals {
  test_config = {

    baseline_ec2_instances = {

      test-managementserver-2022 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "nomis_windows_server_2022_jumpserver_release_*"
          # availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/ndh-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        tags = {
          description = "Windows Server 2022 Management server for NDH"
          os-type     = "Windows"
          component   = "managementserver"
          server-type = "ndh-management-server"
        }
      }

      t1-ndh-app-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "nomis_data_hub_rhel_7_9_app_release_2023-05-02T00-00-47.783Z"
        })
        instance             = merge(module.baseline_presets.ec2_instance.instance.default, {})
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        tags = {
          description = "Standalone EC2 for testing RHEL7.9 NDH App"
          component   = "ndh"
          server-type = "ndh-app"
          monitored   = false
        }
      }

      t1-ndh-ems-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "nomis_data_hub_rhel_7_9_ems_test_2023-04-02T00-00-21.281Z"
        })
        instance             = merge(module.baseline_presets.ec2_instance.instance.default, {})
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        tags = {
          description = "Standalone EC2 for testing RHEL7.9 NDH ems"
          component   = "ndh"
          server-type = "ndh-ems"
          monitored   = false
        }
      }
    }
    baseline_ec2_autoscaling_group = {
      # Example ASG using base image with ansible provisioning
      # Include the autoscale-trigger-hook ansible role when using hooks
      # dev-base-rhel79 = {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name = "base_rhel_7_9_*"
      #   })
      #   instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      #     vpc_security_group_ids = ["private"]
      #   })
      #   user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      #   autoscaling_group = {
      #     desired_capacity    = 1
      #     max_size      #       # = 2
      #     vpc_zone_identifier = module.environment.subnets["private"].ids
      #   }
      #   autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      #   tags = {
      #     description = "For testing with official RedHat RHEL7.9 image"
      #     os-type     = "Linux"
      #     component   = "test"
      #     server-type = "set me to the ansible server type group vars"
      #   }
      #
      # Example target group setup below
      #
      #   lb_target_groups = {
      #     http-7777 = {
      #       port                 = 7777
      #       protocol             = "HTTP"
      #       target_type          = "instance"
      #       deregistration_delay = 30
      #       health_check = {
      #         enabled             = true
      #         interval            = 30
      #         healthy_threshold   = 3
      #         matcher             = "200-399"
      #         path                = "/"
      #         port                = 7777
      #         timeout             = 5
      #         unhealthy_threshold = 5
      #       }
      #       stickiness = {
      #         enabled = true
      #         type    = "lb_cookie"
      #       }
      #     }
      #   }
      # }



    }

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
  }
}
