locals {

  ec2_autoscaling_groups = {

    jumpserver = {
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
        ami_name                      = "hmpps_windows_server_2019_release_2024-*"
        availability_zone             = null
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        ssm_parameters_prefix         = "ec2/"
        secretsmanager_secrets_prefix = "ec2/"
        subnet_name                   = "private"
        user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false
        vpc_security_group_ids       = ["private-jumpserver"]
      }
      tags = {
        backup                 = "false" # no need to back this up as they are destroyed each night
        component              = "test"
        description            = "Windows Server 2019 jumpserver client testing for Nomis Combined Reporting"
        instance-access-policy = "full"
        os-type                = "Windows"
        server-type            = "NcrClient"
      }
    }
  }
}
