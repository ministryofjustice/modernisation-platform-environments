locals {
  ec2_instances = {

    web = {
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2026-09-14T16-17-24.564Z"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-london-unpaid-work"
        instance_profile_policies = [
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        subnet_name = "private"
      }

      ebs_volumes = {
        "/dev/sda1" = {
          size = 30
          type = "gp3"
        }
      }

      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = null
        metadata_options_http_tokens = "optional"
        vpc_security_group_ids       = ["ec2-windows"]
      }

      tags = {
        ami                    = "hmpps_windows_server_2022_release_2026-09-14T16-17-24.564Z"
        backup                 = "false" # disable mod platform backup since everything is in code
        component              = "web"
        description            = "London Unpaid Work Web Server"
        instance-access-policy = "limited"
        os-type                = "Windows"
        server-type            = "london-unpaid-work-web"
      }
    }

    api = {
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2026-09-14T16-17-24.564Z"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-london-unpaid-work"
        instance_profile_policies = [
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
      }

      ebs_volumes = {
        "/dev/sda1" = {
          size = 30
          type = "gp3"
        }
      }

      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = null
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["ec2-windows"]
      }

      tags = {
        backup                 = "false"
        component              = "api"
        description            = "London Unpaid Work API Server"
        instance-access-policy = "limited"
        os-type                = "Windows"
        server-type            = "london-unpaid-work-api"
      }
    }
  }
}
