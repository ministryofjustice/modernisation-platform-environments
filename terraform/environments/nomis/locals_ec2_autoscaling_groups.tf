locals {

  ec2_autoscaling_groups = {
    client = {
      autoscaling_group = {
        desired_capacity    = 1
        force_delete        = true
        max_size            = 1
        vpc_zone_identifier = module.environment.subnets["private"].ids
        warm_pool = {
          min_size          = 0
          reuse_on_scale_in = true
        }
      }
      autoscaling_schedules = {
        "scale_up"   = { recurrence = "0 7 * * Mon-Fri" }
        "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
      }
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2024-*"
        ebs_volumes_copy_all_from_ami = false # ami has unwanted ephemeral devices
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/"
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "private"
        user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        vpc_security_group_ids       = ["private-jumpserver"]
        metadata_options_http_tokens = "required"
        monitoring                   = false
      }
      tags = {
        description            = "Windows Server 2022 client testing for NOMIS"
        instance-access-policy = "full"
        os-type                = "Windows"
        component              = "test"
        server-type            = "NomisClient"
        backup                 = "false" # no need to back this up as they are destroyed each night
      }
    }

    web = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      config = {
        ami_name                  = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
        availability_zone         = null # use all AZs since latency not an issue
        iam_resource_names_prefix = "ec2-weblogic"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/" # TODO can be removed with line below
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t2.xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "optional"
        monitoring                   = false
        vpc_security_group_ids       = ["private-web"]
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
      user_data_cloud_init = {
        args = {
          lifecycle_hook_name  = "ready-hook"
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = "--tags ec2provision"
        }
        scripts = [
          "install-ssm-agent.sh.tftpl",
          "ansible-ec2provision.sh.tftpl",
          "post-ec2provision.sh.tftpl"
        ]
      }
      tags = {
        ami                    = "nomis_rhel_6_10_weblogic_appserver_10_3"
        backup                 = "false" # disable mod platform backup since everything is in code
        component              = "web"
        description            = "nomis weblogic appserver 10.3"
        instance-access-policy = "limited"
        os-type                = "Linux"
        server-type            = "nomis-web"
      }
    }

    web19c = {
      autoscaling_group = {
        desired_capacity    = 1
        force_delete        = true
        max_size            = 1
        vpc_zone_identifier = module.environment.subnets["private"].ids
        warm_pool = {
          min_size          = 0
          reuse_on_scale_in = true
        }
      }
      autoscaling_schedules = {
        "scale_up"   = { recurrence = "0 7 * * Mon-Fri" }
        "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
      }
      config = {
        ami_name                  = "base_ol_8_5*"
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/"
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "private"
      }
      ebs_volumes = {
        "/dev/sdb" = { label = "app", type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        vpc_security_group_ids       = ["private-web"]
        metadata_options_http_tokens = "required"
        monitoring                   = false
      }
      user_data_cloud_init = {
        args = {
          lifecycle_hook_name  = "ready-hook"
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = "--tags ec2provision"
        }
        scripts = [
          "install-ssm-agent.sh.tftpl",
          "ansible-ec2provision.sh.tftpl",
          "post-ec2provision.sh.tftpl"
        ]
      }
      tags = {
        description = "For testing nomis weblogic 19c image"
        # ami       = "base_ol_8_5" # commented out to ensure harden role does not re-run
        os-type     = "Linux"
        component   = "web"
        server-type = "nomis-web19c"
      }
    }
  }
}
