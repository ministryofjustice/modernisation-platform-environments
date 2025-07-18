locals {

  ec2_instances = {

    app = {
      cloudwatch_metric_alarms = merge(
        local.cloudwatch_metric_alarms.windows,
        local.cloudwatch_metric_alarms.app,
      )
      config = {
        ami_owner                     = "self"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
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
        disable_api_termination      = true
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        tags = {
          backup-plan = "daily-and-weekly"
        }
        vpc_security_group_ids = ["app", "ad-join", "ec2-windows"]
      }
      route53_records = {
        create_external_record = true
        create_internal_record = true
      }
      tags = {
        backup    = "false" # disable mod platform backup since we use our own policies
        os-type   = "Windows"
        component = "app"
      }
    }

    db = {
      cloudwatch_metric_alarms = merge(
        local.cloudwatch_metric_alarms.db,
        local.cloudwatch_metric_alarms.db_backup,
      )
      config = {
        ami_owner                     = "self"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        subnet_name = "private"
      }
      ebs_volumes = {
        "/dev/sdb" = { label = "app" }   # /u01
        "/dev/sdc" = { label = "app" }   # /u02
        "/dev/sde" = { label = "data" }  # DATA01
        "/dev/sdf" = { label = "data" }  # DATA02
        "/dev/sdg" = { label = "data" }  # DATA03
        "/dev/sdh" = { label = "data" }  # DATA04
        "/dev/sdi" = { label = "data" }  # DATA05
        "/dev/sdj" = { label = "flash" } # FLASH01
        "/dev/sdk" = { label = "flash" } # FLASH02
        "/dev/sds" = { label = "swap" }
      }
      ebs_volume_config = {
        data  = { iops = 3000, throughput = 125 }
        flash = { iops = 3000, throughput = 125 }
      }
      instance = {
        disable_api_termination      = true
        instance_type                = "r6i.xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
        tags = {
          backup-plan = "daily-and-weekly"
        }
        vpc_security_group_ids = ["database", "oem-agent", "ec2-linux"]
      }
      route53_records = {
        create_external_record = true
        create_internal_record = true
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
          "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
          "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
        ]
      }
      tags = {
        ami         = "base_ol_8_5"
        backup      = "false" # disable mod platform backup since we use our own policies
        os-type     = "Linux"
        component   = "data"
        server-type = "csr-db"
      }
    }

    web = {
      cloudwatch_metric_alarms = merge(
        local.cloudwatch_metric_alarms.windows,
        local.cloudwatch_metric_alarms.web,
      )
      config = {
        ami_owner                     = "self"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
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
        disable_api_termination      = true
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        tags = {
          backup-plan = "daily-and-weekly"
        }
        vpc_security_group_ids = ["web", "ad-join", "ec2-windows"]
      }
      route53_records = {
        create_external_record = true
        create_internal_record = true
      }
      tags = {
        backup    = "false" # disable mod platform backup since we use our own policies
        os-type   = "Windows"
        component = "web"
      }
    }

    prisoner-retail = {
      cloudwatch_metric_alarms = merge(
        local.cloudwatch_metric_alarms.windows,
      )
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2024-*"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
          "Ec2PrisonerRetailPolicy"
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
        tags = {
          backup-plan = "daily-and-weekly"
        }
        vpc_security_group_ids = [
          "prisoner-retail",
          "ad-join",
          "ec2-windows"
        ]
      }
      route53_records = {
        create_external_record = false
        create_internal_record = false
      }
      tags = {
        backup      = "false" # disable mod platform backup since we use our own policies
        os-type     = "Windows"
        server-type = "PrisonerRetail"
      }
    }
  }
}
