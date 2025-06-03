locals {

  ec2_instances = {

    bip_app = {
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
        instance_type           = "m6i.4xlarge"
        key_name                = "ec2-user"
        vpc_security_group_ids  = ["bip"]
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
        description            = "ncr bip mid-tier component"
        instance-access-policy = "full"
        os-type                = "Linux"
        server-type            = "ncr-bip-app"
        update-ssm-agent       = "patchgroup1"
      }
    }

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
        vpc_security_group_ids  = ["bip"]
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
        description            = "ncr bip CMS"
        instance-access-policy = "full"
        os-type                = "Linux"
        server-type            = "ncr-bip-cms"
        update-ssm-agent       = "patchgroup1"
      }
    }

    bip_webadmin = {
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
        instance_type           = "r6i.large"
        key_name                = "ec2-user"
        vpc_security_group_ids  = ["web"]
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
        description            = "ncr bip web for CMS"
        instance-access-policy = "full"
        os-type                = "Linux"
        server-type            = "ncr-webadmin"
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
        vpc_security_group_ids  = ["web"]
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
        server-type            = "ncr-web"
        update-ssm-agent       = "patchgroup1"
      }
    }

    bods = {
      config = {
        ami_name                      = "hmpps_windows_server_2019_release_*"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-etl"
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
        "/dev/sda1" = { type = "gp3", size = 100 } # root volume
        "xvdd"      = { type = "gp3", size = 100 } # D:/ Temp
        "xvde"      = { type = "gp3", size = 100 } # E:/ App
        "xvdf"      = { type = "gp3", size = 100 } # F:/ Storage
      }
      instance = {
        disable_api_termination = false
        instance_type           = "t3.large"
        key_name                = "ec2-user"
        vpc_security_group_ids  = ["etl"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      tags = {
        ami                    = "hmpps_windows_server_2019"
        backup                 = "false"
        instance-access-policy = "full"
        os-type                = "Windows"
        server-type            = "Bods"
        update-ssm-agent       = "patchgroup1"
      }
    }

    db = {
      config = {
        ami_name                  = "hmpps_ol_8_5_oracledb_19c_release_2023-08-08T13-49-56.195Z"
        ami_owner                 = "self"
        iam_resource_names_prefix = "ec2-database"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Db",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/"
        subnet_name                   = "data"
      }
      ebs_volumes = {
        "/dev/sdb" = { type = "gp3", label = "app", size = 200 }   # /u01
        "/dev/sdc" = { type = "gp3", label = "app", size = 500 }   # /u02
        "/dev/sde" = { type = "gp3", label = "data", size = 500 }  # DATA01
        "/dev/sdj" = { type = "gp3", label = "flash", size = 200 } # FLASH01
        "/dev/sds" = { type = "gp3", label = "swap", size = 4 }
      }
      instance = {
        disable_api_termination      = true
        instance_type                = "r6i.xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
        vpc_security_group_ids       = ["data"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      secretsmanager_secrets = {
        asm-passwords = {
          description             = "Oracle ASM passwords generated by oracle-19c ansible role"
          recovery_window_in_days = 0 # so instances can be deleted and re-created without issue
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
        ami                  = "hmpps_ol_8_5_oracledb_19c"
        backup               = false
        server-type          = "ncr-db"
        os-type              = "Linux"
        licence-requirements = "Oracle Database"
        update-ssm-agent     = "patchgroup1"
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
        disable_api_termination = false
        instance_type           = "m4.large"
        key_name                = "ec2-user"
        vpc_security_group_ids  = ["private-jumpserver"]
      }
      tags = {
        ami                    = "hmpps_windows_server_2019"
        backup                 = "false" # no need to backup as these shouldn't contain persistent data
        description            = "Windows Server 2012 R2 client testing for NART"
        instance-access-policy = "full"
        os-type                = "Windows"
        server-type            = "NcrClient"
        update-ssm-agent       = "patchgroup1"
      }
    }
  }
}
