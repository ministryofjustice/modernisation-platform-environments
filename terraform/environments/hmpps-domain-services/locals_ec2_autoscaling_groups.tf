locals {

  ec2_autoscaling_groups = {
    base_linux = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      autoscaling_schedules = {
        scale_up   = { recurrence = "0 7 * * Mon-Fri" }
        scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
      }
      config = {
        iam_resource_names_prefix = "ec2-instance"
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
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false
        vpc_security_group_ids       = ["rds-ec2s"]
      }
      user_data_cloud_init = {
        args = {
          lifecycle_hook_name  = "ready-hook"
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = "--tags ec2provision"
        }
        scripts = [
          "install-ssm-agent.sh.tftpl",
          "ansible-ec2provision.sh.tftpl",
          "post-ec2provision.sh.tftpl"
        ]
      }
      tags = {
        component = "test"
        os-type   = "Linux"
      }
    }

    base_windows = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      autoscaling_schedules = {
        scale_up   = { recurrence = "0 7 * * Mon-Fri" }
        scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
      }
      config = {
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
        user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 128 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false
        vpc_security_group_ids       = ["rds-ec2s"]
      }
      tags = {
        component = "test"
        os-type   = "Windows"
      }
    }
  }
}
