locals {
  test_config = {

    baseline_ec2_instances = {

      test-management-server-2022 = local.management_server_2022

      test-ndh-app-a = local.ndh_app_a

      test-ndh-ems-a = local.ndh_ems_a
    
    }
    baseline_ec2_autoscaling_groups = {
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

    baseline_route53_zones = {
      "test.ndh.nomis.service.justice.gov.uk" = {
        records = [
          { name = "t1-app", type = "A", ttl = 300, records = ["10.101.3.196"] },
          { name = "t1-ems", type = "A", ttl = 300, records = ["10.101.3.197"] },
          { name = "t2-app", type = "A", ttl = 300, records = ["10.101.33.196"] },
          { name = "t2-ems", type = "A", ttl = 300, records = ["10.101.33.197"] },
        ]
      }
    }
  }
}
