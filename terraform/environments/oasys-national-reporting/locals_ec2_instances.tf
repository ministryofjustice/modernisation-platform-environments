locals {

  ec2_instances = {

    bip_cms = {
      config = {
        ami_name                  = "base_rhel_8_5_2023-07*" # RHEL 8.8
        iam_resource_names_prefix = "ec2-bip"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
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
        vpc_security_group_ids  = ["bip-app"]
        tags = {
          backup-plan = "daily-and-weekly"
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
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
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
        vpc_security_group_ids  = ["bip-web"]
        tags = {
          backup-plan = "daily-and-weekly"
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
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
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
        vpc_security_group_ids       = ["bods", "oasys_db"]
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

    boe_app = {
      config = {
        ami_name                  = "base_rhel_6_10_*"
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
      }
      ebs_volumes = {
        # FIXME: ebs_volumes list is NOT YET CORRECT and will need to change
        "/dev/sda1" = { type = "gp3", size = 128 } # root volume
        "/dev/sdb"  = { type = "gp3", size = 128 } # /u01
        "/dev/sdc"  = { type = "gp3", size = 128 } # /u02
        "/dev/sds"  = { type = "gp3", size = 128 } # swap
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "optional" # required as Rhel 6 cloud-init does not support IMDSv2
        vpc_security_group_ids       = ["boe", "oasys_db"]
        tags = {
          backup-plan         = "daily-and-weekly"
          instance-scheduling = "skip-scheduling"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
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
        ami              = "base_rhel_6_10"
        backup           = "false"
        component        = "boe"
        os-type          = "Linux"
        server-type      = "onr-boe"
        update-ssm-agent = "patchgroup1"
      }
    }

    boe_web = {
      config = {
        ami_name                  = "base_rhel_7_9_*"
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 32 }  # root volume
        "/dev/sdb"  = { type = "gp3", size = 128 } # /u01
        "/dev/sdc"  = { type = "gp3", size = 128 } # /u02
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["web"]
        tags = {
          backup-plan         = "daily-and-weekly"
          instance-scheduling = "skip-scheduling"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
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
        ami              = "base_rhel_7_9"
        backup           = "false"
        os-type          = "Linux"
        component        = "web"
        server-type      = "onr-web"
        update-ssm-agent = "patchgroup1"
      }
    }

    jumpserver = {
      config = {
        ami_name                      = "base_windows_server_2012_r2_release_2024-*"
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
        "/dev/sda1" = { type = "gp3", size = 200 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "m4.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["private-jumpserver"]
      }
      tags = {
        backup                 = "false" # no need to backup as these shouldn't contain persistent data
        component              = "test"
        description            = "Windows Server 2012 R2 client testing for NART"
        instance-access-policy = "full"
        os-type                = "Windows"
        server-type            = "OnrClient"
        update-ssm-agent       = "patchgroup1"
      }
      cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.windows
    }
  }
}
