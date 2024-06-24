locals {
  ###
  #  web
  ###

  webserver = {
    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default
    cloudwatch_metric_alarms = merge(
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
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "oasys_webserver_release_2023-07-02*"
      iam_resource_names_prefix = "ec2-web"
      ssm_parameters_prefix     = "ec2-web/"
      availability_zone         = null
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      monitoring             = true
      vpc_security_group_ids = ["private_web"]
    })
    lb_target_groups = {
      pv-http-8080 = local.target_group_http_8080
      pb-http-8080 = local.target_group_http_8080
    }
    secretsmanager_secrets = {
      maintenance_message = {
        description             = "OASys maintenance message. Use \\n for new lines"
        recovery_window_in_days = 0
        tags = {
          instance-access-policy     = "full"
          instance-management-policy = "full"
        }
      }
    }
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
    tags = {
      component        = "web"
      description      = "${local.environment} oasys web"
      environment-name = terraform.workspace
      monitored        = true
      os-type          = "Linux"
      os-major-version = 7
      os-version       = "RHEL 7.9"
      server-type      = "oasys-web"
    }
  }

  target_group_http_8080 = {
    deregistration_delay = 30
    port                 = 8080
    protocol             = "HTTP"

    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 8080
      protocol            = "HTTP"
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  ###
  #  db
  ###

  database_a = {
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
    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name          = "oasys_oracle_db_release_2023-06-26T10-16-03.670Z"
      ami_owner         = "self"
      availability_zone = "eu-west-2a"
      instance_profile_policies = flatten([
        module.baseline_presets.ec2_instance.config.db.instance_profile_policies,
      ])
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default_db, {
      instance_type = "r6i.4xlarge"
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    user_data_cloud_init   = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
    route53_records        = module.baseline_presets.ec2_instance.route53_records.internal_and_external
    secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_19c
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
      server-type                 = "oasys-db"
    }
  }
  database_b = merge(local.database_a, {
    config = merge(local.database_a.config, {
      availability_zone = "eu-west-2b"
    })
  })

  ###
  #  db ONR
  ###

  database_onr_a = {
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
    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name = "base_rhel_7_9_2024-01-01T00-00-06.493Z"
      # Uses base ami as Nomis DB ami not available in oasys env. 
      # Requires ssm_agent_ansible_no_tags set in user_data to execute all ansible amibuild and ec2provision steps
      availability_zone = "eu-west-2a"
      instance_profile_policies = flatten([
        module.baseline_presets.ec2_instance.config.db.instance_profile_policies,
      ])
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default_db, {
      instance_type = "r6i.4xlarge"
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    route53_records        = module.baseline_presets.ec2_instance.route53_records.internal_and_external
    secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_11g
    user_data_cloud_init   = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
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
      server-type                 = "onr-db"
    }
  }
  database_onr_b = merge(local.database_onr_a, {
    config = merge(local.database_onr_a.config, {
      availability_zone = "eu-west-2b"
    })
  })

  ###
  #  bip
  ###

  bip_a = {
    cloudwatch_metric_alarms = merge(
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
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "oasys_bip_release_2023-12-02*"
      availability_zone         = "eu-west-2a"
      iam_resource_names_prefix = "ec2"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.xlarge"
      monitoring             = true
      vpc_security_group_ids = ["bip"]

      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    secretsmanager_secrets = {}
    user_data_cloud_init   = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
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
      server-type         = "oasys-bip"
    }
  }
  bip_b = merge(local.bip_a, {
    config = merge(local.bip_a.config, {
      availability_zone = "eu-west-2b"
    })
  })

  # audit vault

  audit_vault = {
    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name          = "OL8.9-x86_64-HVM-2024-02-02"
      availability_zone = "eu-west-2b"
      instance_profile_policies = flatten([
        module.baseline_presets.ec2_instance.config.db.instance_profile_policies,
      ])
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default_db, {
      instance_type = "r6i.4xlarge"
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    user_data_cloud_init   = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
    route53_records        = module.baseline_presets.ec2_instance.route53_records.internal_and_external
    secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_19c
    tags = {
      backup                      = "false" # opt out of mod platform default backup plan
      component                   = "data"
      description                 = "${local.environment} oasys audit vault"
      environment-name            = terraform.workspace # used in provisioning script to select group vars
      licence-requirements        = "Oracle Database"
      monitored                   = false
      OracleDbLTS-ManagedInstance = true # oracle license tracking
      os-type                     = "Oracle"
      os-major-version            = 8
      os-version                  = "Oracle Linux 8.9"
      server-type                 = "oasys-av"
    }
  }

}
