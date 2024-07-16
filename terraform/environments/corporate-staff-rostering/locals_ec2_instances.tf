locals {

  ec2_instances = {

    app = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2,
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_windows,
        local.application_log_metric_alarms.app, {
          instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_or_cwagent_stopped_windows["instance-or-cloudwatch-agent-stopped"], {
            threshold           = "0"
            evaluation_periods  = "5"
            datapoints_to_alarm = "2"
            period              = "60"
            alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
          })
          high-memory-usage = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_windows["high-memory-usage"], {
            threshold           = "75"
            period              = "60" # seconds
            evaluation_periods  = "20"
            datapoints_to_alarm = "20"
            alarm_description   = "Triggers if the average memory utilization is 75% or above for 20 minutes. Set below the default of 95% to allow enough time to establish an RDP session to fix the issue."
          })
        }
      )
      config = {
        ami_owner                     = "self"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/" # TODO
        ssm_parameters_prefix         = "ec2/" # TODO
        subnet_name                   = "private"
      }
      instance = {
        disable_api_stop             = false # TODO
        disable_api_termination      = true
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = true
        tags = {
          backup-plan         = "daily-and-weekly"
          instance-scheduling = "skip-scheduling" # TODO
        }
        vpc_security_group_ids = ["domain", "app", "jumpserver"]
      }
      route53_records = {
        create_external_record = true
        create_internal_record = true
      }
      tags = {
        backup    = "false" # disable mod platform backup since we use our own policies
        os-type   = "Windows"
        component = "app"
      }
    }

    db = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2,
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_linux,
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_cwagent_collectd_oracle_db_backup, {
          # TODO review
          cpu-utilization-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2["cpu-utilization-high"], {
            evaluation_periods  = "480"
            datapoints_to_alarm = "480"
            threshold           = "95"
            alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 8 hours to allow for DB refreshes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"
          })
          cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_linux["cpu-iowait-high"], {
            evaluation_periods  = "480"
            datapoints_to_alarm = "480"
            threshold           = "40"
            alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 8 hours allowing for DB refreshes.  See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
          })
          instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_or_cwagent_stopped_linux["instance-or-cloudwatch-agent-stopped"], {
            threshold           = "0"
            evaluation_periods  = "5"
            datapoints_to_alarm = "2"
            period              = "60"
            alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
          })
        }
      )
      config = {
        ami_owner                     = "self"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/"
        ssm_parameters_prefix         = "ec2/" # TODO
        subnet_name                   = "private"
      }
      ebs_volumes = {
        "/dev/sdb" = { label = "app" }   # /u01
        "/dev/sdc" = { label = "app" }   # /u02
        "/dev/sde" = { label = "data" }  # DATA01
        "/dev/sdf" = { label = "data" }  # DATA02
        "/dev/sdg" = { label = "data" }  # DATA03
        "/dev/sdh" = { label = "data" }  # DATA04
        "/dev/sdi" = { label = "data" }  # DATA05
        "/dev/sdj" = { label = "flash" } # FLASH01
        "/dev/sdk" = { label = "flash" } # FLASH02
        "/dev/sds" = { label = "swap" }
      }
      ebs_volume_config = {
        data  = { iops = 3000, throughput = 125 }
        flash = { iops = 3000, throughput = 125 }
      }
      instance = {
        disable_api_stop             = false # TODO
        disable_api_termination      = true
        instance_type                = "r6i.xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
        tags = {
          backup-plan         = "daily-and-weekly"
          instance-scheduling = "skip-scheduling" # TODO
        }
        vpc_security_group_ids = ["database"]
      }
      route53_records = {
        create_external_record = true
        create_internal_record = true
      }
      secretsmanager_secrets = {
        asm-passwords = {
          description             = "Oracle ASM passwords generated by oracle-19c ansible role"
          recovery_window_in_days = 0 # so instances can be deleted and re-created without issue
        }
      }
      # TODO
      user_data_cloud_init = {
        args = {
          lifecycle_hook_name  = "ready-hook"
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = "--tags ec2provision"
        }
        scripts = [
          "ansible-ec2provision.sh.tftpl",
          "post-ec2provision.sh.tftpl"
        ]
      }
      tags = {
        ami         = "base_ol_8_5"
        backup      = "false" # disable mod platform backup since we use our own policies
        os-type     = "Linux"
        component   = "data"
        server-type = "csr-db"
      }
    }

    web = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2,
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_windows,
        local.application_log_metric_alarms.web, {
          instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_or_cwagent_stopped_windows["instance-or-cloudwatch-agent-stopped"], {
            threshold           = "0"
            evaluation_periods  = "5"
            datapoints_to_alarm = "2"
            period              = "60"
            alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
          })
        }
      )
      config = {
        ami_owner                     = "self"
        availability_zone             = "eu-west-2a"
        ebs_volumes_copy_all_from_ami = false
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/" # TODO
        ssm_parameters_prefix         = "ec2/" # TODO
        subnet_name                   = "private"
      }
      instance = {
        disable_api_stop             = false # TODO
        disable_api_termination      = true
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = true
        tags = {
          backup-plan         = "daily-and-weekly"
          instance-scheduling = "skip-scheduling" # TODO
        }
        vpc_security_group_ids = ["domain", "web", "jumpserver"]
      }
      route53_records = {
        create_external_record = true
        create_internal_record = true
      }
      tags = {
        backup    = "false" # disable mod platform backup since we use our own policies
        os-type   = "Windows"
        component = "web"
      }
    }
  }
}
