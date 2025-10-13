locals {

  ec2_instances = {

    ndh_app = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_linux,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_textfile_monitoring,
      )
      config = {
        ami_name                  = "nomis_data_hub_rhel_7_9_app_release_2023-05-02T00-00-47.783Z"
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["ndh_app", "ec2-linux"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      user_data_cloud_init = {
        args = {
          branch       = "main"
          ansible_args = "--tags ec2provision"
        }
        scripts = [ # paths are relative to templates/ dir
          "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
          "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
          "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
        ]
      }
      tags = {
        backup                 = "false"
        description            = "RHEL7.9 NDH App"
        instance-access-policy = "limited"
        instance-scheduling    = "skip-scheduling"
        os-type                = "Linux"
        server-type            = "ndh-app"
        update-ssm-agent       = "patchgroup1"
      }
    }

    ndh_ems = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_linux,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
      )
      config = {
        ami_name                  = "nomis_data_hub_rhel_7_9_ems_release_2023-05-02T00-00-34.669Z"
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["ndh_ems", "ec2-linux"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      user_data_cloud_init = {
        args = {
          branch       = "main"
          ansible_args = "--tags ec2provision"
        }
        scripts = [ # paths are relative to templates/ dir
          "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
          "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
          "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
        ]
      }
      tags = {
        backup                 = "false"
        description            = "RHEL7.9 NDH ems"
        instance-access-policy = "limited"
        instance-scheduling    = "skip-scheduling"
        server-type            = "ndh-ems"
        os-type                = "Linux"
        update-ssm-agent       = "patchgroup1"
      }
    }

    ndh_mgmt = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
        # Disable these alarms until some way of handling "stopped" instances is implemented
        # module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
      )
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2023-*"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
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
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["management_server", "ec2-windows", "ad-join"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      tags = {
        backup           = "false"
        description      = "Windows Server 2022 Management server for NDH"
        os-type          = "Windows"
        server-type      = "NdhMgmt"
        update-ssm-agent = "patchgroup1"
      }
    }
  }

}
