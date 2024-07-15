locals {

  ec2_instances = {

    ndh_app = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
        # module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_textfile_monitoring, # TODO ADD
      )
      config = {
        ami_name                  = "nomis_data_hub_rhel_7_9_app_release_2023-05-02T00-00-47.783Z"
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        ssm_parameters_prefix = "ec2/" # TODO REMOVE
        subnet_name           = "private"
      }
      instance = {
        disable_api_termination      = false # TODO set to TRUE
        instance_type                = "t3.xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false # TODO change to true
        vpc_security_group_ids       = ["ndh_app"]
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
        description            = "RHEL7.9 NDH App"
        component              = "ndh"
        instance-access-policy = "limited"
        instance-scheduling    = "skip-scheduling"
        monitored              = false # TODO remove
        os-type                = "Linux"
        server-type            = "ndh-app"
      }
    }

    ndh_ems = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
      )
      config = {
        ami_name                  = "nomis_data_hub_rhel_7_9_ems_release_2023-05-02T00-00-34.669Z"
        iam_resource_names_prefix = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        ssm_parameters_prefix = "ec2/" # TODO REMOVE
        subnet_name           = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false # TODO change to true
        vpc_security_group_ids       = ["ndh_ems"]
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
        description            = "RHEL7.9 NDH ems"
        component              = "ndh"
        server-type            = "ndh-ems"
        os-type                = "Linux"
        monitored              = false
        instance-access-policy = "limited"
        instance-scheduling    = "skip-scheduling"
      }
    }

    ndh_mgmt = {
      # ami has unwanted ephemeral device, don't copy all the ebs_volumess
      config = {
        ami_name                      = "hmpps_windows_server_2022_release_2023-*"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        subnet_name           = "private"
        ssm_parameters_prefix = "ec2/" # TODO REMOVE
        user_data_raw         = base64encode(file("./templates/ndh-user-data.yaml"))
      }
      ebs_volumes = {
        "/dev/sda1" = { type = "gp3", size = 100 }
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false
        vpc_security_group_ids       = ["management_server"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      tags = {
        description = "Windows Server 2022 Management server for NDH"
        os-type     = "Windows"
        component   = "managementserver"
        server-type = "ndh-management-server"
      }
    }
  }

}
