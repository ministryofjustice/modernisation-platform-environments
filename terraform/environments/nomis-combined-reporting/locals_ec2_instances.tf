locals {

  ec2_instances = {

    bip_app = {
      config = {
        ami_name                  = "base_rhel_8_5_*"
        iam_resource_names_prefix = "ec2-bip"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        ssm_parameters_prefix     = "ec2/" #TODO
        subnet_name = "private"
      }
      ebs_volumes = {
        "/dev/sdb" = { type = "gp3", size = 100 }
        "/dev/sdc" = { type = "gp3", size = 100 }
        "/dev/sds" = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        monitoring                   = false # TODO
        vpc_security_group_ids       = ["bip"]
        #tags = {
        #  backup-plan         = "daily-and-weekly"
        #  instance-scheduling = "skip-scheduling"
        #}
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
        ami         = "base_rhel_8_5"
        description = "ncr bip mid-tier component"
        # backup           = "false"
        component              = "mid"
        instance-access-policy = "full"
        os-type                = "Linux"
        server-type            = "ncr-bip"
        # update-ssm-agent = "patchgroup1"
      }
    }

    bip_web = {
      config = {
        ami_name                  = "base_rhel_8_5_*"
        iam_resource_names_prefix = "ec2-web"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        ssm_parameters_prefix     = "web/"
        subnet_name = "private"
      }
      ebs_volumes = {
        "/dev/sdb" = { type = "gp3", size = 100 }
        "/dev/sdc" = { type = "gp3", size = 100 }
        "/dev/sds" = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        monitoring                   = false # TODO
        vpc_security_group_ids       = ["web"]
        #tags = {
        #  backup-plan         = "daily-and-weekly"
        #  instance-scheduling = "skip-scheduling"
        #}
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
        ami = "base_rhel_8_5"
        # backup           = "false"
        component              = "web"
        instance-access-policy = "full"
        os-type                = "Linux"
        server-type            = "ncr-web"
        # update-ssm-agent = "patchgroup1"
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
        ssm_parameters_prefix     = "ec2/" #TODO
        subnet_name = "private"
        user_data_raw = base64encode(templatefile(
          "../../modules/baseline_presets/ec2-user-data/user-data-pwsh.yaml.tftpl", {
            branch = "main"
          }
        ))
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
        "/dev/sdb"  = { type = "gp3", size = 100 }
        "/dev/sdc"  = { type = "gp3", size = 100 }
        "/dev/sds"  = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        monitoring                   = false
        vpc_security_group_ids       = ["etl"]
        #tags = {
        #  backup-plan         = "daily-and-weekly"
        #  instance-scheduling = "skip-scheduling"
        #}
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      tags = {
        #ami = "hmpps_windows_server_2019"
        ami = "windows_server_2019"
        # backup           = "false"
        component              = "etl"
        instance-access-policy = "full"
        os-type                = "Windows"
        server-type            = "etl" # TODO
        # update-ssm-agent = "patchgroup1"
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
        ssm_parameters_prefix         = "ec2/"
        secretsmanager_secrets_prefix = "ec2/"
        subnet_name                   = "data"
      }

      ebs_volumes = {
        "/dev/sdb" = { type = "gp3", label = "app", size = 100 }   # /u01
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
        monitoring                   = true
        vpc_security_group_ids       = ["data"]
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

      user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

      tags = {
        ami = "hmpps_ol_8_5_oracledb_19c"
        # backup               = false
        component            = "data"
        server-type          = "ncr-db"
        os-type              = "Linux"
        os-version           = "RHEL 8.5"
        licence-requirements = "Oracle Database"
        # update-ssm-agent = "patchgroup1"
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
    }
  }
}
