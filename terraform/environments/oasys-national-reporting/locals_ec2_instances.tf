locals {

  ec2_instances = {

    bip_cms = {
      config = {
        ami_name                  = "base_rhel_8_5_2023-07*" # RHEL 8.8
        iam_resource_names_prefix = "ec2-bip"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
      }
      ebs_volumes = {
        "/dev/sdb" = { type = "gp3", size = 100 }
        "/dev/sdc" = { type = "gp3", size = 100 }
        "/dev/sds" = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination = false
        instance_type           = "m6i.xlarge"
        key_name                = "ec2-user"
        vpc_security_group_ids  = ["bip-app", "ec2-linux"]
        tags = {
          backup-plan   = "daily-and-weekly"
          patch-manager = "manual"
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
        ami                    = "base_rhel_8_5"
        backup                 = "false"
        description            = "onr bip CMS"
        instance-access-policy = "full"
        os-type                = "Linux"
        server-type            = "onr-bip-cms"
        update-ssm-agent       = "patchgroup1"
      }
    }

    bip_web = {
      config = {
        ami_name                  = "base_rhel_8_5_2023-07*" # RHEL 8.8
        iam_resource_names_prefix = "ec2-web"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
      }
      ebs_volumes = {
        "/dev/sdb" = { type = "gp3", size = 100 }
        "/dev/sdc" = { type = "gp3", size = 100 }
        "/dev/sds" = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination = false
        instance_type           = "r6i.xlarge"
        key_name                = "ec2-user"
        vpc_security_group_ids  = ["bip-web", "ec2-linux"]
        tags = {
          backup-plan   = "daily-and-weekly"
          patch-manager = "manual"
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
        ami                    = "base_rhel_8_5"
        backup                 = "false"
        instance-access-policy = "full"
        os-type                = "Linux"
        server-type            = "onr-web"
        update-ssm-agent       = "patchgroup1"
      }
    }

    bods = {
      config = {
        ami_name                      = "hmpps_windows_server_2019_release_*"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
        user_data_raw = base64encode(templatefile(
          "./templates/user-data-onr-bods-pwsh.yaml.tftpl", {
            branch = "main"
          }
        ))
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 128 } # root volume
        "xvdd"      = { type = "gp3", size = 128 } # D:/ Temp
        "xvde"      = { type = "gp3", size = 128 } # E:/ App
        "xvdf"      = { type = "gp3", size = 700 } # F:/ Storage
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["bods", "ec2-windows", "ad-join"]
        tags = {
          backup-plan         = "daily-and-weekly"
          instance-scheduling = "skip-scheduling"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      tags = {
        ami              = "hmpps_windows_server_2019"
        backup           = "false"
        component        = "onr_bods"
        os-type          = "Windows"
        server-type      = "Bods"
        update-ssm-agent = "patchgroup1"
      }
    }

    windows_bip = {
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2025-*"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
        user_data_raw = base64encode(templatefile(
          "./templates/user-data-onr-bip-pwsh.yaml.tftpl", {
            branch = "main"
          }
        ))
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 160 } # root volume
        "xvdd"      = { type = "gp3", size = 384 } # D:/ Temp
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "r6i.2xlarge" # Memory optimised 8 vCPU, 64 GiB RAM
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["bods", "ec2-windows", "ad-join"]
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      tags = {
        ami              = "hmpps_windows_server_2022"
        backup           = "false" # no need to backup as this is just for migrating data
        description      = "Windows Server 2022 BIP instance for NART"
        os-type          = "Windows"
        server-type      = "BIPTemp"
        update-ssm-agent = "patchgroup1"
      }
      cloudwatch_metric_alarms = {} # no alarms set as this is a temporary instance for migrating data
    }
  }
}
