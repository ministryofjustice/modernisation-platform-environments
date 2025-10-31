locals {

  ec2_instances = {

    app = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
        local.cloudwatch_metric_alarms.windows,
      )
      config = {
        ami_owner                     = "self"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
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
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids = [
          "app",
          "ad-join",
          "ec2-windows",
        ]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      tags = {
        backup           = "false"
        component        = "app"
        os-type          = "Windows"
        update-ssm-agent = "patchgroup1"
      }
    }

    db = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
      )
      config = {
        availability_zone             = "eu-west-2a"
        ami_owner                     = "self"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
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
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids = [
          "database",
          "ad-join",
          "ec2-windows",
        ]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      tags = {
        backup           = "false"
        component        = "database"
        os-type          = "Windows"
        update-ssm-agent = "patchgroup1"
      }
    }

    web = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
        local.cloudwatch_metric_alarms.windows,
      )
      config = {
        availability_zone             = "eu-west-2a"
        ami_owner                     = "self"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/"
        subnet_name                   = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids = [
          "web",
          "ad-join",
          "ec2-windows",
        ]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      secretsmanager_secrets = {
        web-cert = {
          description             = "Certificate secrets used for IIS Web Binding"
          recovery_window_in_days = 0 # so instances can be deleted and re-created without issue
        }
      }
      tags = {
        backup           = "false"
        component        = "web"
        os-type          = "Windows"
        server-type      = "PlanetFMWeb"
        update-ssm-agent = "patchgroup1"
      }
    }
  }
}
