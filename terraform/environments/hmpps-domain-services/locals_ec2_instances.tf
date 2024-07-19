locals {

  ec2_instances = {
    rdgw = {
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
          "SSMPolicy",
          "PatchBucketAccessPolicy",
        ]
        secretsmanager_secrets_prefix = "ec2/" # TODO
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "private"
        user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
        # user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false
        vpc_security_group_ids       = ["rds-ec2s"]
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      tags = {
        os-type     = "Windows"
        component   = "remotedesktop"
        backup-plan = "daily-and-weekly" # TODO
      }
    }
    rds = {
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
          "SSMPolicy",
          "PatchBucketAccessPolicy",
        ]
        secretsmanager_secrets_prefix = "ec2/" # TODO
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "private"
        user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
        # user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false
        vpc_security_group_ids       = ["rds-ec2s"]
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      tags = {
        os-type     = "Windows"
        component   = "remotedesktop"
        backup-plan = "daily-and-weekly" # TODO
      }
    }
  }
}

