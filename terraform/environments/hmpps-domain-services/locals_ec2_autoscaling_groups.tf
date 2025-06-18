locals {

  ec2_autoscaling_groups = {
    base_linux = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      autoscaling_schedules = {
        scale_up   = { recurrence = "0 7 * * Mon-Fri" }
        scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
      }
      config = {
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids = [
          "ec2-linux",
          "ad-join",
        ]
        tags = {
          patch-manager = "group2"
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
        backup           = "false"
        os-type          = "Linux"
        server-type      = "hmpps-domain-services"
        update-ssm-agent = "patchgroup1"
      }
    }

    base_windows = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      autoscaling_schedules = {
        scale_up   = { recurrence = "0 7 * * Mon-Fri" }
        scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
      }
      config = {
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
        user_data_raw = base64encode(templatefile(
          "../../modules/baseline_presets/ec2-user-data/user-data-pwsh.yaml.tftpl", {
            branch = "main"
          }
        ))
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 128 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids = [
          "ad-join",
          "ec2-windows",
          "rd-session-host",
        ]
        tags = {
          patch-manager = "group2"
        }
      }
      tags = {
        backup           = "false"
        os-type          = "Windows"
        server-type      = "HmppsDomainServicesTest"
        update-ssm-agent = "patchgroup1"
      }
    }

    rdgw = {
      autoscaling_group = {
        desired_capacity          = 1
        max_size                  = 1
        force_delete              = true
        vpc_zone_identifier       = module.environment.subnets["private"].ids
        wait_for_capacity_timeout = 0

        initial_lifecycle_hooks = {
          "ready-hook" = {
            default_result       = "ABANDON"
            heartbeat_timeout    = 2700 # 45 minutes
            lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
          }
        }
      }
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2024-*"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
        user_data_raw = base64encode(templatefile(
          "../../modules/baseline_presets/ec2-user-data/user-data-pwsh-asg-ready-hook.yaml.tftpl", {
            branch = "main"
          }
        ))
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids = [
          "rdgw",
          "ad-join",
          "ec2-windows",
        ]
        tags = {
          patch-manager = "group2"
        }
      }
      lb_target_groups = {
        http = local.lbs.public.instance_target_groups.http
      }
      tags = {
        backup           = "false"
        description      = "Remote Desktop Gateway Windows Server 2022"
        os-type          = "Windows"
        server-type      = "RDGateway"
        update-ssm-agent = "patchgroup1"
      }
    }

    rds = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
        #wait_for_capacity_timeout = 0

        #initial_lifecycle_hooks = {
        #  "ready-hook" = {
        #    default_result       = "ABANDON"
        #    heartbeat_timeout    = 2700 # 45 minutes
        #    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
        #  }
        #}
      }
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2024-*"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
        user_data_raw = base64encode(templatefile(
          #"../../modules/baseline_presets/ec2-user-data/user-data-pwsh-asg-ready-hook.yaml.tftpl", {
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
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids = [
          "rds",
          "ad-join",
          "ec2-windows",
        ]
        tags = {
          patch-manager = "group2"
        }
      }
      lb_target_groups = {
        https = local.lbs.public.instance_target_groups.https
      }
      tags = {
        backup           = "false"
        description      = "Remote Desktop Services Connection Broker and Web Windows Server 2022"
        os-type          = "Windows"
        server-type      = "RDServices"
        update-ssm-agent = "patchgroup1"
      }
    }
  }
}
