# csr-development environment settings
locals {

  baseline_presets_development = {
    options = {
      cloudwatch_metric_oam_links_ssm_parameters = [] # disable in dev as environment gets nuked
      cloudwatch_metric_oam_links                = [] # disable in dev as environment gets nuked
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    ec2_autoscaling_groups = {
      dev-base-ol85 = {
        autoscaling_group = {
          desired_capacity    = 0
          force_delete        = true
          max_size            = 1
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = {
          scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
          scale_up   = { recurrence = "0 7 * * Mon-Fri" }
        }
        config = {
          ami_name                      = "base_ol_8_5_*"
          ebs_volumes_copy_all_from_ami = true
          iam_resource_names_prefix     = "ec2-instance"
          instance_profile_policies = [
            "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
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
          metadata_options_http_tokens = "required"
          vpc_security_group_ids = [
            "database",
            "ec2-linux",
            "oem-agent",
          ]
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
          description      = "For testing our base OL8.5 base image"
          os-type          = "Linux"
          server-type      = "base-ol85"
          update-ssm-agent = "patchgroup1"
        }
      }

      dev-tst = {
        autoscaling_group = {
          desired_capacity    = 0
          force_delete        = true
          max_size            = 1
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = {
          scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
          scale_up   = { recurrence = "0 7 * * Mon-Fri" }
        }
        config = {
          ami_name                      = "base_windows_server_2012_r2_release_2023-*"
          ami_owner                     = "374269020027"
          ebs_volumes_copy_all_from_ami = false
          iam_resource_names_prefix     = "ec2-instance"
          instance_profile_policies = [
            "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
            "CSRWebServerPolicy",
          ]
          subnet_name = "private"
          user_data_raw = base64encode(templatefile(
            "../../modules/baseline_presets/ec2-user-data/user-data-pwsh.yaml.tftpl", {
              branch = "main"
            }
          ))
        }
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 192 } # minimum size has to be 128 due to snapshot sizes
        }
        instance = {
          disable_api_termination      = false
          instance_type                = "t3.medium"
          key_name                     = "ec2-user"
          metadata_options_http_tokens = "required"
          vpc_security_group_ids = [
            "web",
            "ad-join",
            "ec2-windows",
          ]
        }
        tags = {
          backup           = "false"
          description      = "Test AWS AMI Windows Server 2012 R2"
          os-type          = "Windows"
          server-type      = "Base2012"
          update-ssm-agent = "patchgroup1"
        }
      }

      dev-win-2022 = {
        autoscaling_group = {
          desired_capacity    = 0
          force_delete        = true
          max_size            = 1
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = {
          scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
          scale_up   = { recurrence = "0 7 * * Mon-Fri" }
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
            "CSRWebServerPolicy",
          ]
          subnet_name = "private"
          user_data_raw = base64encode(templatefile(
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
            "web",
            "ad-join",
            "ec2-windows",
          ]
        }
        tags = {
          backup           = "false"
          description      = "Windows Server 2022 for testing"
          os-type          = "Windows"
          server-type      = "Base2022"
          update-ssm-agent = "patchgroup1"
        }
      }
    }

    ec2_instances = {}

    iam_policies = {
    }


  }
}
