locals {

  ec2_instances = {

    bods = {
      config = {
        ami_name                      = "hmpps_windows_server_2019_release_*" # wildcard to latest. EC2 instance versions ami_name must be fixed
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        secretsmanager_secrets_prefix = "ec2/" # TODO
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "private"
        user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
      }
      ebs_volumes = {
        # FIXME: ebs_volumes list is NOT YET CORRECT and will need to change
        "/dev/sda1" = { type = "gp3", size = 128 } # root volume
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false
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
        component = "onr_bods"
        os-type   = "Windows"
      }
    }

    boe_app = {
      config = {
        ami_name                      = "base_rhel_6_10_*"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = true
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        secretsmanager_secrets_prefix = "ec2/"
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "private"
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
        monitoring                   = false
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
      user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      tags = {
        ami         = "base_rhel_6_10"
        os-type     = "Linux"
        component   = "boe"
        server-type = "onr-boe"
      }
    }

    boe_web = {
      config = {
        ami_name                      = "base_rhel_7_9_*"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = true
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        secretsmanager_secrets_prefix = "ec2/"
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "private"
        tags = {
          backup-plan         = "daily-and-weekly"
          instance-scheduling = "skip-scheduling"
        }
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
        monitoring                   = false
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
      user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      tags = {
        ami         = "base_rhel_7_9"
        os-type     = "Linux"
        component   = "web"
        server-type = "onr-web"
      }
    }

    jumpserver = {
      config = {
        ami_name                      = "base_windows_server_2012_r2_release_2024-*"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        secretsmanager_secrets_prefix = "ec2/" # TODO
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "private"
        user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 200 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "m4.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false
        vpc_security_group_ids       = ["private-jumpserver"]
      }
      tags = {
        description            = "Windows Server 2012 R2 client testing for NART"
        instance-access-policy = "full"
        os-type                = "Windows"
        component              = "test"
        server-type            = "OnrClient"
        backup                 = "false" # no need to backup as these shouldn't contain persistent data
      }
    }
  }
}
