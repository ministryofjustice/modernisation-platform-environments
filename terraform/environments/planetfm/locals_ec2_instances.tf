locals {

  ec2_instances = {

    app = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows, { # TODO update defaults to match
          instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["planetfm_pagerduty"].ec2_instance_or_cwagent_stopped_windows["instance-or-cloudwatch-agent-stopped"], {
            threshold           = "0"
            evaluation_periods  = "5"
            datapoints_to_alarm = "2"
            period              = "60"
            alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
          })
        }
      )
      config = {
        availability_zone             = "eu-west-2a"
        ami_owner                     = "self"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/" # TODO remove
        ssm_parameters_prefix         = "ec2/" # TODO remove
        subnet_name                   = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["domain", "app", "jumpserver", "remotedesktop_sessionhost"]

        tags = {
          backup-plan         = "daily-and-weekly"
          instance-scheduling = "skip-scheduling"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      tags = {
        # backup = "false" # TODO
        component = "app"
        os-type   = "Windows"
      }
    }

    db = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows, { # TODO update defaults to match
          instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["planetfm_pagerduty"].ec2_instance_or_cwagent_stopped_windows["instance-or-cloudwatch-agent-stopped"], {
            threshold           = "0"
            evaluation_periods  = "5"
            datapoints_to_alarm = "2"
            period              = "60"
            alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
          })
        }
      )
      config = {
        availability_zone             = "eu-west-2a"
        ami_owner                     = "self"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/" # TODO remove
        ssm_parameters_prefix         = "ec2/" # TODO remove
        subnet_name                   = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["domain", "database", "jumpserver"]

        tags = {
          backup-plan         = "daily-and-weekly"
          instance-scheduling = "skip-scheduling"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      tags = {
        # backup = "false" # TODO
        component = "database"
        os-type   = "Windows"
      }
    }

    web = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows, { # TODO update defaults to match
          instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["planetfm_pagerduty"].ec2_instance_or_cwagent_stopped_windows["instance-or-cloudwatch-agent-stopped"], {
            threshold           = "0"
            evaluation_periods  = "5"
            datapoints_to_alarm = "2"
            period              = "60"
            alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
          })
        }
      )
      config = {
        availability_zone             = "eu-west-2a"
        ami_owner                     = "self"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/" # TODO remove
        ssm_parameters_prefix         = "ec2/" # TODO remove
        subnet_name                   = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.large"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["domain", "web", "jumpserver", "remotedesktop_sessionhost"]

        tags = {
          backup-plan         = "daily-and-weekly"
          instance-scheduling = "skip-scheduling"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      tags = {
        # backup = "false" # TODO
        component = "web"
        os-type   = "Windows"
      }
    }
  }
}
