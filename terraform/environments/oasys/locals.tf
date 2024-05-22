# env independent common vars
# env independent webserver vars

locals {

  baseline_s3_buckets = {
    (terraform.workspace) = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }
  ###
  ### env independent common vars
  ###

  business_unit  = "hmpps"
  networking_set = "general"

  environment_baseline_presets_options = {
    development   = local.development_baseline_presets_options
    test          = local.test_baseline_presets_options
    preproduction = local.preproduction_baseline_presets_options
    production    = local.production_baseline_presets_options
  }

  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }

  environment_config = local.environment_configs[local.environment]

  baseline_environment_presets_options = local.environment_baseline_presets_options[local.environment]
  baseline_environment_config          = local.environment_configs[local.environment]

  region            = "eu-west-2"
  availability_zone = "eu-west-2a"

  baseline_presets_options = {
    cloudwatch_log_groups = null
    # cloudwatch_metric_alarms_default_actions     = ["dso_pagerduty"]
    enable_application_environment_wildcard_cert = false # only use if you'll be attaching hmpps-<enviornment>.modernisation-platform... to load balancers or using for https
    enable_backup_plan_daily_and_weekly          = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_ec2_user_keypair                      = true
    enable_ec2_oracle_enterprise_managed_server  = true
    enable_azure_sas_token                       = true
    enable_shared_s3                             = true # adds permissions to ec2s to interact with devtest or prodpreprod buckets
    db_backup_s3                                 = true # adds db backup buckets
    db_backup_more_permissions                   = true
    iam_policies_ec2_default                     = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies                              = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_filter                          = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy", "Ec2OracleEnterpriseManagerPolicy"]
  }

  ######
  ### env independent webserver vars
  ######

  ###
  #  web
  ###

  webserver = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "oasys_webserver_release_2023-07-02*"
      ssm_parameters_prefix     = "ec2-web/"
      iam_resource_names_prefix = "ec2-web"
      availability_zone         = null
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      monitoring             = true
      vpc_security_group_ids = ["private_web"]
    })
    cloudwatch_metric_alarms = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
    )
    user_data_cloud_init  = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
    autoscaling_schedules = {}
    autoscaling_group     = module.baseline_presets.ec2_autoscaling_group.default
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
    lb_target_groups = {
      pv-http-8080 = local.target_group_http_8080
      pb-http-8080 = local.target_group_http_8080
    }
    tags = {
      component         = "web"
      description       = "${local.environment} oasys web"
      os-type           = "Linux"
      os-major-version  = 7
      os-version        = "RHEL 7.9"
      "Patch Group"     = "RHEL"
      server-type       = "oasys-web"
      monitored         = true
      oasys-environment = local.environment
      environment-name  = terraform.workspace
      #oracle-db-hostname = "T2ODL0009.azure.noms.root"
      oracle-db-sid = "OASPROD" # for each env using azure DB will need to be OASPROD
    }
  }

  target_group_http_8080 = {
    port                 = 8080
    protocol             = "HTTP"
    deregistration_delay = 30
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
    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name          = "oasys_oracle_db_release_2023-06-26T10-16-03.670Z"
      ami_owner         = "self"
      availability_zone = "${local.region}a"
      instance_profile_policies = flatten([
        module.baseline_presets.ec2_instance.config.db.instance_profile_policies,
      ])
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default_db, {
      tags = {
        backup-plan = "daily-and-weekly"
      }
      instance_type = "r6i.4xlarge"
    })
    cloudwatch_metric_alarms = merge(
      # standard
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dso_pagerduty"].ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_service_status_app,
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
      # db_connected
      # DBAs have slack integration via OEM for this so don't include pagerduty integration
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_connected,
      # db_backup
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_oracle_db_backup,
    )
    autoscaling_schedules = {}
    autoscaling_group     = module.baseline_presets.ec2_autoscaling_group.default
    user_data_cloud_init  = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
    ebs_volumes = {
      "/dev/sdb" = { # /u01
        size  = 100
        label = "app"
        type  = "gp3"
      }
      "/dev/sdc" = { # /u02
        size  = 1000
        label = "app"
        type  = "gp3"
      }
      "/dev/sde" = { # DATA01
        label = "data"
        size  = 2000
        type  = "gp3"
      }
      "/dev/sdf" = { # DATA02
        label = "data"
        size  = 2000
        type  = "gp3"
      }
      # "/dev/sdg" = {  # DATA03
      # }
      # "/dev/sdh" = {  # DATA04
      # }
      # "/dev/sdi" = {  # DATA05
      # }
      "/dev/sdj" = { # FLASH01
        label = "flash"
        type  = "gp3"
        size  = 1000
      }
      # "/dev/sdk" = { # FLASH02
      # }
      "/dev/sds" = {
        label = "swap"
        type  = "gp3"
        size  = 2
      }
    }
    ebs_volume_config = {
      data = {
        iops       = 12000 # min 3000
        type       = "gp3"
        throughput = 750
        total_size = 200
      }
      flash = {
        iops       = 5000 # min 3000
        type       = "gp3"
        throughput = 500
        total_size = 50
      }
    }
    route53_records        = module.baseline_presets.ec2_instance.route53_records.internal_and_external
    secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_19c
    # Example target group setup below
    lb_target_groups = {}
    tags = {
      backup                      = "false" # opt out of mod platform default backup plan
      component                   = "data"
      oracle-sids                 = "OASPROD BIPINFRA"
      os-type                     = "Linux"
      os-major-version            = 8
      os-version                  = "RHEL 8.5"
      licence-requirements        = "Oracle Database"
      "Patch Group"               = "RHEL"
      server-type                 = "oasys-db"
      description                 = "${local.environment} oasys database"
      monitored                   = true
      oasys-environment           = local.environment
      environment-name            = terraform.workspace # used in provisioning script to select group vars
      OracleDbLTS-ManagedInstance = true                # oracle license tracking
    }
  }
  database_b = merge(local.database_a, {
    config = merge(local.database_a.config, {
      availability_zone = "${local.region}b"
    })
  })

  ###
  #  db ONR
  ###

  database_onr_a = {
    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name = "base_rhel_7_9_2024-01-01T00-00-06.493Z"
      # Uses base ami as Nomis DB ami not available in oasys env. 
      # Requires ssm_agent_ansible_no_tags set in user_data to execute all ansible amibuild and ec2provision steps
      availability_zone = "${local.region}a"
      instance_profile_policies = flatten([
        module.baseline_presets.ec2_instance.config.db.instance_profile_policies,
      ])
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default_db, {
      tags = {
        backup-plan = "daily-and-weekly"
      }
      instance_type = "r6i.4xlarge"
    })
    cloudwatch_metric_alarms = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
      {
        cpu-utilization-high = {
          comparison_operator = "GreaterThanOrEqualToThreshold"
          evaluation_periods  = "120"
          datapoints_to_alarm = "120"
          metric_name         = "CPUUtilization"
          namespace           = "AWS/EC2"
          period              = "60"
          statistic           = "Maximum"
          threshold           = "95"
          alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 2 hours on an oasys-db instance"
          alarm_actions       = ["dso_pagerduty"]
        }
      }
    )
    autoscaling_schedules = {}
    autoscaling_group     = module.baseline_presets.ec2_autoscaling_group.default
    user_data_cloud_init  = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
    ebs_volumes = {
      "/dev/sdb" = { # /u01
        size  = 100
        label = "app"
        type  = "gp3"
      }
      "/dev/sdc" = { # /u02
        size  = 500
        label = "app"
        type  = "gp3"
      }
      "/dev/sde" = { # DATA01
        label = "data"
        size  = 2000
        type  = "gp3"
      }
      # "/dev/sdf" = { # DATA02
      #   label = "data"
      #   size  = 2000
      #   type  = "gp3"
      # }
      # "/dev/sdg" = {  # DATA03
      # }
      # "/dev/sdh" = {  # DATA04
      # }
      # "/dev/sdi" = {  # DATA05
      # }
      "/dev/sdj" = { # FLASH01
        label = "flash"
        type  = "gp3"
        size  = 600
      }
      # "/dev/sdk" = { # FLASH02
      # }
      "/dev/sds" = {
        label = "swap"
        type  = "gp3"
        size  = 2
      }
    }
    ebs_volume_config = {
      data = {
        iops       = 12000
        type       = "gp3"
        throughput = 750
        total_size = 200
      }
      flash = {
        iops       = 5000
        type       = "gp3"
        throughput = 500
        total_size = 50
      }
    }
    route53_records        = module.baseline_presets.ec2_instance.route53_records.internal_and_external
    secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_11g
    # Example target group setup below
    lb_target_groups = {}
    tags = {
      backup                      = "false" # opt out of mod platform default backup plan
      component                   = "data"
      oracle-sids                 = "OASPROD BIPINFRA"
      os-type                     = "Linux"
      os-major-version            = 8
      os-version                  = "RHEL 8.5"
      licence-requirements        = "Oracle Database"
      "Patch Group"               = "RHEL"
      server-type                 = "onr-db"
      description                 = "${local.environment} onr database"
      monitored                   = true
      oasys-environment           = local.environment
      environment-name            = terraform.workspace # used in provisioning script to select group vars
      OracleDbLTS-ManagedInstance = true                # oracle license tracking
    }
  }
  database_onr_b = merge(local.database_onr_a, {
    config = merge(local.database_onr_a.config, {
      availability_zone = "${local.region}b"
    })
  })

  ###
  #  bip
  ###

  bip_a = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "oasys_bip_release_2023-12-02*"
      iam_resource_names_prefix = "ec2"
      availability_zone         = "${local.region}a"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.xlarge"
      monitoring             = true
      vpc_security_group_ids = ["bip"]
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    cloudwatch_metric_alarms = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
    )
    user_data_cloud_init  = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
    autoscaling_schedules = {}
    autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
      desired_capacity = 1
      max_size         = 1
    })
    lb_target_groups       = {}
    secretsmanager_secrets = {}
    tags = {
      backup              = "false" # opt out of mod platform default backup plan
      component           = "bip"
      description         = "${local.environment} oasys bip"
      os-type             = "Linux"
      os-major-version    = 7
      os-version          = "RHEL 7.9"
      "Patch Group"       = "RHEL"
      server-type         = "oasys-bip"
      monitored           = true
      oasys-environment   = local.environment
      environment-name    = terraform.workspace
      instance-scheduling = "skip-scheduling"
    }
  }
  bip_b = merge(local.bip_a, {
    config = merge(local.bip_a.config, {
      availability_zone = "${local.region}b"
    })
  })

  ###
  #  other
  ###

  public_key_data = jsondecode(file("./files/bastion_linux.json"))

  baseline_cloudwatch_metric_alarms      = {}
  baseline_cloudwatch_log_metric_filters = {}
  baseline_cloudwatch_log_groups         = {}
  baseline_ec2_autoscaling_groups        = {}
  baseline_ec2_instances                 = {}
  baseline_iam_service_linked_roles      = {}
  baseline_key_pairs                     = {}
  baseline_kms_grants                    = {}
  baseline_lbs                           = {}
  baseline_route53_resolvers             = {}
  baseline_route53_zones                 = {}
  baseline_secretsmanager_secrets        = {}
  baseline_sns_topics                    = {}
  baseline_ssm_parameters                = {}
  baseline_iam_policies                  = {}
  baseline_iam_roles                     = {}

  environment_cloudwatch_monitoring_options = {
    development   = local.development_cloudwatch_monitoring_options
    test          = local.test_cloudwatch_monitoring_options
    preproduction = local.preproduction_cloudwatch_monitoring_options
    production    = local.production_cloudwatch_monitoring_options
  }

  cloudwatch_local_environment_monitoring_options = local.environment_cloudwatch_monitoring_options[local.environment]

  cloudwatch_monitoring_options = {
    enable_cloudwatch_monitoring_account    = false
    enable_cloudwatch_cross_account_sharing = false
    enable_cloudwatch_dashboard             = false
    monitoring_account_id                   = {}
    source_account_ids                      = {}
  }
}
