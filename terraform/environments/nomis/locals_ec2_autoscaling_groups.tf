locals {

  ec2_autoscaling_groups = {
    base = {
      autoscaling_group = {
        desired_capacity    = 0
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      autoscaling_schedules = {
        "scale_up"   = { recurrence = "0 7 * * Mon-Fri" }
        "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
      }
      config = {
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        subnet_name = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        vpc_security_group_ids       = ["private-web"]
        metadata_options_http_tokens = "required"
      }
      user_data_cloud_init = {
        args = {
          branch       = "main"
          ansible_args = "--tags ec2provision"
        }
        scripts = [ # paths are relative to templates/ dir
          "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
          "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
          "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
        ]
      }
      tags = {
        backup           = "false"
        component        = "test"
        os-type          = "Linux"
        update-ssm-agent = "patchgroup1"
      }
    }

    client = {
      autoscaling_group = {
        desired_capacity          = 1
        force_delete              = true
        max_size                  = 1
        vpc_zone_identifier       = module.environment.subnets["private"].ids
        wait_for_capacity_timeout = 0
        warm_pool = {
          min_size          = 0
          reuse_on_scale_in = true
        }
        # Comment these lines in when ready-hooks are going to be deployed
        # initial_lifecycle_hooks = {
        #   "ready-hook" = {
        #     default_result       = "ABANDON"
        #     heartbeat_timeout    = 2700 # 45 minutes
        #     lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
        #   }
        # }        
      }
      autoscaling_schedules = {
        "scale_up"   = { recurrence = "0 6 * * Mon-Fri" }
        "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
      }
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2024-*"
        ebs_volumes_copy_all_from_ami = false # ami has unwanted ephemeral devices
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        subnet_name = "private"
        user_data_raw = base64encode(templatefile(
          # Swap this line with the one below when this is going to be implemented
          # "../../modules/baseline_presets/ec2-user-data/user-data-pwsh-asg-ready-hook.yaml.tftpl", { 
          "../../modules/baseline_presets/ec2-user-data/user-data-pwsh.yaml.tftpl", {
            branch = "main"
          }
        ))
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["private-jumpserver"]
      }
      tags = {
        backup                          = "false"
        component                       = "test"
        description                     = "Windows Server 2022 client testing for NOMIS"
        instance-access-policy          = "full"
        os-type                         = "Windows"
        server-type                     = "NomisClient"
        update-ssm-agent                = "patchgroup1"
        update-configuration-management = "patchgroup1"
      }
    }

    web = {
      autoscaling_group = {
        desired_capacity          = 1
        max_size                  = 1
        force_delete              = true
        vpc_zone_identifier       = module.environment.subnets["private"].ids
        wait_for_capacity_timeout = 0

        warm_pool = {
          min_size          = 0
          reuse_on_scale_in = true
        }
      }
      config   = local.ec2_instances.web.config
      instance = local.ec2_instances.web.instance
      lb_target_groups = {
        http-7777 = {
          deregistration_delay = 30
          port                 = 7777
          protocol             = "HTTP"

          health_check = {
            enabled             = true
            healthy_threshold   = 3
            interval            = 10
            matcher             = "200-399"
            path                = "/keepalive.htm"
            port                = 7777
            protocol            = "HTTP"
            timeout             = 5
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "lb_cookie"
          }
        }
      }
      user_data_cloud_init = local.ec2_instances.web.user_data_cloud_init
      tags                 = local.ec2_instances.web.tags
    }

    web12 = {
      autoscaling_group = {
        desired_capacity          = 1
        force_delete              = true
        max_size                  = 1
        vpc_zone_identifier       = module.environment.subnets["private"].ids
        wait_for_capacity_timeout = 0
        warm_pool = {
          min_size          = 0
          reuse_on_scale_in = true
        }
      }
      autoscaling_schedules = {
        "scale_up"   = { recurrence = "0 6 * * Mon-Fri" }
        "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
      }
      config = {
        ami_name                  = "base_ol_8_5*"
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        subnet_name = "private"
      }
      ebs_volumes = {
        "/dev/sdb" = { label = "app", type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        vpc_security_group_ids       = ["private-web"]
        metadata_options_http_tokens = "required"
      }
      lb_target_groups = {
        http-7777 = {
          deregistration_delay = 30
          port                 = 7777
          protocol             = "HTTP"

          health_check = {
            enabled             = true
            healthy_threshold   = 3
            interval            = 10
            matcher             = "200-399"
            path                = "/"
            port                = 7777
            protocol            = "HTTP"
            timeout             = 5
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "lb_cookie"
          }
        }
      }
      user_data_cloud_init = {
        args = {
          branch       = "main"
          ansible_args = "--tags ec2provision"
        }
        scripts = [ # paths are relative to templates/ dir
          "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
          "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
          "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
        ]
      }
      tags = {
        # ami       = "base_ol_8_5" # commented out to ensure harden role does not re-run
        backup           = "false"
        component        = "web"
        description      = "For testing nomis weblogic 12 image"
        os-type          = "Linux"
        server-type      = "nomis-web12"
        update-ssm-agent = "patchgroup1"
      }
    }

    web19c = {
      autoscaling_group = {
        desired_capacity          = 1
        force_delete              = true
        max_size                  = 1
        vpc_zone_identifier       = module.environment.subnets["private"].ids
        wait_for_capacity_timeout = 0
        warm_pool = {
          min_size          = 0
          reuse_on_scale_in = true
        }
      }
      autoscaling_schedules = {
        "scale_up"   = { recurrence = "0 6 * * Mon-Fri" }
        "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
      }
      config = {
        ami_name                  = "base_ol_8_5*"
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        subnet_name = "private"
      }
      ebs_volumes = {
        "/dev/sdb" = { label = "app", type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        vpc_security_group_ids       = ["private-web"]
        metadata_options_http_tokens = "required"
      }
      lb_target_groups = {
        http-7777 = {
          deregistration_delay = 30
          port                 = 7777
          protocol             = "HTTP"

          health_check = {
            enabled             = true
            healthy_threshold   = 3
            interval            = 10
            matcher             = "200-399"
            path                = "/"
            port                = 7777
            protocol            = "HTTP"
            timeout             = 5
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "lb_cookie"
          }
        }
      }
      user_data_cloud_init = {
        args = {
          branch       = "main"
          ansible_args = "--tags ec2provision"
        }
        scripts = [ # paths are relative to templates/ dir
          "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
          "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
          "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
        ]
      }
      tags = {
        # ami       = "base_ol_8_5" # commented out to ensure harden role does not re-run
        backup           = "false"
        component        = "web"
        description      = "For testing nomis weblogic 19c image"
        os-type          = "Linux"
        server-type      = "nomis-web19c"
        update-ssm-agent = "patchgroup1"
      }
    }
  }
}
