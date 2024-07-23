locals {

  ec2_instances = {

    bip = {
      cloudwatch_metric_alarms = merge(
        # TODO
        module.baseline_presets.cloudwatch_metric_alarms.ec2,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
        {
          low-inodes = {
            comparison_operator = "GreaterThanOrEqualToThreshold"
            evaluation_periods  = "15"
            datapoints_to_alarm = "15"
            metric_name         = "collectd_inode_used_percent_value"
            namespace           = "CWAgent"
            period              = "60"
            statistic           = "Maximum"
            threshold           = "85"
            alarm_description   = "Triggers if free inodes falls below the threshold for an hour"
            alarm_actions       = ["dso_pagerduty"]
          }
        }
      )
      config = {
        ami_name                  = "oasys_bip_release_2023-12-02*"
        iam_resource_names_prefix = "ec2"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/"
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        vpc_security_group_ids       = ["bip"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      secretsmanager_secrets = {}
      user_data_cloud_init = {
        args = {
          lifecycle_hook_name  = "ready-hook"
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = "" # built from base AMI to amibuild and ec2provision tasks are run
        }
        scripts = [
          "install-ssm-agent.sh.tftpl",
          "ansible-ec2provision.sh.tftpl",
          "post-ec2provision.sh.tftpl"
        ]
      }
      tags = {
        backup              = "false" # opt out of mod platform default backup plan
        component           = "bip"
        description         = "${local.environment} oasys bip"
        environment-name    = terraform.workspace
        instance-scheduling = "skip-scheduling"
        monitored           = true
        os-major-version    = 7
        os-type             = "Linux"
        os-version          = "RHEL 7.9"
        "Patch Group"       = "RHEL"
        server-type         = "oasys-bip"
      }
    }

    db11g = {
      cloudwatch_metric_alarms = merge(
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2,
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_cwagent_linux,
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dso_pagerduty"].ec2_instance_cwagent_collectd_service_status_os,
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_service_status_app,
        {
          low-inodes = {
            comparison_operator = "GreaterThanOrEqualToThreshold"
            evaluation_periods  = "15"
            datapoints_to_alarm = "15"
            metric_name         = "collectd_inode_used_percent_value"
            namespace           = "CWAgent"
            period              = "60"
            statistic           = "Maximum"
            threshold           = "85"
            alarm_description   = "Triggers if free inodes falls below the threshold for an hour"
            alarm_actions       = ["dso_pagerduty"]
          }
        },
        local.environment == "production" ? {} : {
          cpu-utilization-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2["cpu-utilization-high"], {
            evaluation_periods  = "480"
            datapoints_to_alarm = "480"
            threshold           = "95"
            alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 8 hours to allow for DB refreshes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"
          })
          cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_cwagent_linux["cpu-iowait-high"], {
            evaluation_periods  = "480"
            datapoints_to_alarm = "480"
            threshold           = "40"
            alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 8 hours allowing for DB refreshes.  See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
          })
        },
        # DBAs have slack integration via OEM for this so don't include pagerduty integration
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_connected,
        # db_backup
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_oracle_db_backup,
      )
      config = {
        # Uses base ami as Nomis DB ami not available in oasys env. 
        ami_name                  = "base_rhel_7_9_2024-01-01T00-00-06.493Z"
        iam_resource_names_prefix = "ec2-database"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Db",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        secretsmanager_secrets_prefix = "ec2/"
        ssm_parameters_prefix         = "ec2/"
        subnet_name                   = "data"
      }
      instance = {
        disable_api_termination      = true
        instance_type                = "r6i.4xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
        monitoring                   = true
        vpc_security_group_ids       = ["data"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      secretsmanager_secrets = {
        asm-passwords = {
          description             = "Oracle ASM passwords generated by oracle-11g ansible role"
          recovery_window_in_days = 0 # so instances can be deleted and re-created without issue
        }
      }
      user_data_cloud_init = {
        args = {
          lifecycle_hook_name  = "ready-hook"
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = "" # built from base AMI to amibuild and ec2provision tasks are run
        }
        scripts = [
          "install-ssm-agent.sh.tftpl",
          "ansible-ec2provision.sh.tftpl",
          "post-ec2provision.sh.tftpl"
        ]
      }
      tags = {
        backup                      = "false" # opt out of mod platform default backup plan
        component                   = "data"
        description                 = "${local.environment} onr database"
        environment-name            = terraform.workspace
        licence-requirements        = "Oracle Database"
        monitored                   = true
        OracleDbLTS-ManagedInstance = true # oracle license tracking
        os-type                     = "Linux"
        os-major-version            = 8
        os-version                  = "RHEL 8.5"
        "Patch Group"               = "RHEL"
        server-type                 = "onr-db"
      }
    }

    db19c = {
      cloudwatch_metric_alarms = merge(
        # standard
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2,
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_cwagent_linux,
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dso_pagerduty"].ec2_instance_cwagent_collectd_service_status_os,
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_service_status_app,
        {
          low-inodes = {
            comparison_operator = "GreaterThanOrEqualToThreshold"
            evaluation_periods  = "15"
            datapoints_to_alarm = "15"
            metric_name         = "collectd_inode_used_percent_value"
            namespace           = "CWAgent"
            period              = "60"
            statistic           = "Maximum"
            threshold           = "85"
            alarm_description   = "Triggers if free inodes falls below the threshold for an hour"
            alarm_actions       = ["dso_pagerduty"]
          }
        },
        local.environment == "production" ? {} : {
          cpu-utilization-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2["cpu-utilization-high"], {
            evaluation_periods  = "480"
            datapoints_to_alarm = "480"
            threshold           = "95"
            alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 8 hours to allow for DB refreshes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"
          })
          cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_cwagent_linux["cpu-iowait-high"], {
            evaluation_periods  = "480"
            datapoints_to_alarm = "480"
            threshold           = "40"
            alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 8 hours allowing for DB refreshes.  See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
          })
        },
        # DBAs have slack integration via OEM for this so don't include pagerduty integration
        module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_connected,
        # db_backup
        module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_oracle_db_backup,
      )
      config = {
        ami_name                  = "oasys_oracle_db_release_2023-06-26T10-16-03.670Z"
        ami_owner                 = "self"
        iam_resource_names_prefix = "ec2-database"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Db",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        ssm_parameters_prefix         = "ec2/"
        secretsmanager_secrets_prefix = "ec2/"
        subnet_name                   = "data"
      }
      instance = {
        disable_api_termination      = true
        instance_type                = "r6i.4xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
        monitoring                   = true
        vpc_security_group_ids       = ["data"]
        tags = {
          backup-plan = "daily-and-weekly"
        }
      }
      user_data_cloud_init = {
        args = {
          lifecycle_hook_name  = "ready-hook"
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = ""
        }
        scripts = [
          "install-ssm-agent.sh.tftpl",
          "ansible-ec2provision.sh.tftpl",
          "post-ec2provision.sh.tftpl"
        ]
      }
      route53_records = {
        create_internal_record = true
        create_external_record = true
      }
      secretsmanager_secrets = {
        asm-passwords = {
          description             = "Oracle ASM passwords generated by oracle-19c ansible role"
          recovery_window_in_days = 0 # so instances can be deleted and re-created without issue
        }
      }
      tags = {
        backup                      = "false" # opt out of mod platform default backup plan
        component                   = "data"
        description                 = "${local.environment} oasys database"
        environment-name            = terraform.workspace # used in provisioning script to select group vars
        licence-requirements        = "Oracle Database"
        monitored                   = true
        OracleDbLTS-ManagedInstance = true # oracle license tracking
        os-type                     = "Linux"
        os-major-version            = 8
        os-version                  = "RHEL 8.5"
        "Patch Group"               = "RHEL"
        server-type                 = "oasys-db"
      }
    }
  }
}
