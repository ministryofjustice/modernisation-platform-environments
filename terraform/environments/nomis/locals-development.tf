# nomis-development environment settings
locals {
  nomis_development = {
    # vars common across ec2 instances
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 90
      }
      cwagent-var-log-messages = {
        retention_days = 30
      }
      cwagent-var-log-secure = {
        retention_days = 90
      }
      cwagent-nomis-autologoff = {
        retention_days = 90
      }
      cwagent-weblogic-logs = {
        retention_days = 30
      }
      cwagent-windows-system = {
        retention_days = 30
      }
    }

    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA

      # add databases here as needed

      # NOTE: Example includes settings for an alarm to check wether the database can connect to the Oracle Enterprise Manager in FixNGo
      # t3-nomis-db-3 = {
      #   tags = {
      #    server-type         = "nomis-db"
      #    description         = "Test database for monitoring automation development"
      #    oracle-sids         = "CNOMT1"
      #    monitored           = false
      #    s3-db-restore-dir   = "CNOMT1_20211214"
      #    # instance-scheduling = "skip-scheduling"
      #    fixngo-connection-target = "10.40.0.136"
      #  }
      #  ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
      #  ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
      #  instance = {
      #    disable_api_termination = true
      #  }
      #  cloudwatch_metric_alarms = {
      #    fixngo-connection = {
      #      comparison_operator = "GreaterThanOrEqualToThreshold"
      #      evaluation_periods  = "3"
      #      namespace           = "CWAgent"
      #      metric_name         = "collectd_exec_value"
      #      period              = "60"
      #      statistic           = "Average"
      #      threshold           = "1"
      #      alarm_description   = "this EC2 instance no longer has a connection to the Oracle Enterprise Manager in FixNGo of the connection-target machine"
      #      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
      #      dimensions = {
      #        instance = "fixngo_connected" # required dimension value for this metric
      #      }
      #    }
      #  }
      #}
    }
    weblogics          = {}
    ec2_test_instances = {}
    ec2_test_autoscaling_groups = {
      dev-redhat-rhel610 = {
        tags = {
          description = "For testing official RedHat RHEL6.10 image"
          monitored   = false
          os-type     = "Linux"
          component   = "test"
        }
        instance = {
          instance_type                = "t2.medium"
          metadata_options_http_tokens = "optional"
        }
        ami_name  = "RHEL-6.10_HVM-*"
        ami_owner = "309956199498"
      }
      dev-redhat-rhel79 = {
        tags = {
          description = "For testing official RedHat RHEL7.9 image"
          monitored   = false
          os-type     = "Linux"
          component   = "test"
        }
        ami_name  = "RHEL-7.9_HVM-*"
        ami_owner = "309956199498"
      }
      dev-base-rhel79 = {
        tags = {
          ami               = "base_rhel_7_9"
          description       = "For testing our base RHEL7.9 base image"
          monitored         = false
          os-type           = "Linux"
          component         = "test"
          nomis-environment = "dev"
          server-type       = "base-rhel79"
        }
        ami_name = "base_rhel_7_9_*"
        autoscaling_group = {
          desired_capacity = 0
        }
      }
      dev-base-rhel610 = {
        tags = {
          ami               = "base_rhel_6_10"
          description       = "For testing our base RHEL6.10 base image"
          monitored         = false
          os-type           = "Linux"
          component         = "test"
          nomis-environment = "dev"
          server-type       = "base-rhel610"
        }
        instance = {
          instance_type                = "t2.medium"
          metadata_options_http_tokens = "optional"
        }
        ami_name = "base_rhel_6_10*"
      }
    }
    ec2_jumpservers = {
      jumpserver-2022 = {
        ami_name = "nomis_windows_server_2022_jumpserver_release_*"
        tags = {
          server-type       = "jumpserver"
          description       = "Windows Server 2022 Jumpserver for NOMIS"
          monitored         = false
          os-type           = "Windows"
          component         = "jumpserver"
          nomis-environment = "dev"
        }
        autoscaling_group = {
          min_size = 0
          max_size = 1
        }
      }
    }
  }
}
