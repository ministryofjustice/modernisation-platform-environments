# ndh-test environment settings
locals {
  ndh_test = {
    ec2_test_instances = {
      # Remove data.aws_kms_key from cmk.tf once the NDH servers are removed
      t1-ndh-app-1 = {
        tags = {
          server-type       = "ndh-app"
          description       = "Standalone EC2 for testing RHEL7.9 NDH App"
          monitored         = false
          os-type           = "Linux"
          component         = "ndh"
          nomis-environment = "t1"
        }
        ebs_volumes = {
          "/dev/sda1" = { kms_key_id = data.aws_kms_key.default_ebs.arn }
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
      }
      t1-ndh-ems-1 = {
        tags = {
          server-type       = "ndh-ems"
          description       = "Standalone EC2 for testing RHEL7.9 NDH EMS"
          monitored         = false
          os-type           = "Linux"
          component         = "ndh"
          nomis-environment = "t1"
        }
        ebs_volumes = {
          "/dev/sda1" = { kms_key_id = data.aws_kms_key.default_ebs.arn }
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
      }
    }
    ec2_test_autoscaling_groups = {
      t1-ndh-app = {
        tags = {
          server-type       = "ndh-app"
          description       = "Standalone EC2 for testing RHEL7.9 NDH App"
          monitored         = false
          os-type           = "Linux"
          component         = "ndh"
          nomis-environment = "t1"
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
        autoscaling_group = {
          desired_capacity = 1
        }
        autoscaling_schedules = {}
        subnet_name           = "data"
      }
      t1-ndh-ems = {
        tags = {
          server-type       = "ndh-ems"
          description       = "Standalone EC2 for testing RHEL7.9 NDH EMS"
          monitored         = false
          os-type           = "Linux"
          component         = "ndh"
          nomis-environment = "t1"
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
        autoscaling_group = {
          desired_capacity = 1
        }
        autoscaling_schedules = {}
        subnet_name           = "data"
      }
    }
  }
}
