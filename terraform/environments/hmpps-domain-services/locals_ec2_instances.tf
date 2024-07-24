locals {

  ec2_instances = {
    rdgw = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarm.ec2,
        # TODO: enable below once CWAgent configured
        # module.baseline_presets.cloudwatch_metric_alarm.ec2_cwagent_windows,
        # module.baseline_presets.cloudwatch_metric_alarm.ec2_instance_or_cwagent_stopped_windows
      )
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2024-01-16T09-48-13.663Z"
        availability_zone             = "eu-west-2a"
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
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["rds-ec2s"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      tags = {
        backup           = "false"
        os-type          = "Windows"
        server-type      = "HmppsRDGateway"
        update-ssm-agent = "patchgroup1"
      }
    }

    rds = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarm.ec2,
        # TODO: enable below once CWAgent configured
        # module.baseline_presets.cloudwatch_metric_alarm.ec2_cwagent_windows,
        # module.baseline_presets.cloudwatch_metric_alarm.ec2_instance_or_cwagent_stopped_windows
      )
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2024-01-16T09-48-13.663Z"
        availability_zone             = "eu-west-2a"
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
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["rds-ec2s"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      tags = {
        backup           = "false"
        os-type          = "Windows"
        server-type      = "HmppsRDServices"
        update-ssm-agent = "patchgroup1"
      }
    }
  }
}

