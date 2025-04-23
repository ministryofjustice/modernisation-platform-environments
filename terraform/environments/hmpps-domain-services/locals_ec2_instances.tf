locals {

  ec2_instances = {

    jumpserver = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
      )

      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2025-*"
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
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["private-jumpserver"]
      }
      tags = {
        ami_name               = "hmpps_windows_server_2022"
        backup                 = "false"
        description            = "Windows Server 2022 jumpserver for Hmpps"
        instance-access-policy = "full"
        os-type                = "Windows"
        server-type            = "HmppsJump2022"
        update-ssm-agent       = "patchgroup1"
      }
    }
    rdgw = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
      )
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2024-01-16T09-48-13.663Z"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "arn:aws:iam::aws:policy/AWSEC2VssSnapshotPolicy",
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
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      tags = {
        backup           = "false"
        os-type          = "Windows"
        server-type      = "RDGateway"
        update-ssm-agent = "patchgroup2"
      }
    }

    rds = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
      )
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2024-01-16T09-48-13.663Z"
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
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      tags = {
        backup           = "false"
        os-type          = "Windows"
        server-type      = "RDServices"
        update-ssm-agent = "patchgroup2"
      }
    }
  }
}

