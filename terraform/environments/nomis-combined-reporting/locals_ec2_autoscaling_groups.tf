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
        disable_api_termination = false
        instance_type           = "t3.large"
        key_name                = "ec2-user"
        vpc_security_group_ids  = ["private-jumpserver"]
      }
      tags = {
        ami_name               = "hmpps_windows_server_2019"
        backup                 = "false"
        description            = "Windows Server 2019 jumpserver client testing for Nomis Combined Reporting"
        instance-access-policy = "full"
        os-type                = "Windows"
        server-type            = "NcrClient"
        update-ssm-agent       = "patchgroup1"
      }
    }
  }
}
