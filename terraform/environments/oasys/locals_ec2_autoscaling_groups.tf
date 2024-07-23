locals {

  ec2_autoscaling_groups = {

    web = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
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
      config = {
        ami_name                  = "oasys_webserver_release_2023-07-02*"
        iam_resource_names_prefix = "ec2-web"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
        ]
        secretsmanager_secrets_prefix = "ec2/"
        ssm_parameters_prefix         = "ec2-web/" # TODO
        subnet_name                   = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = true
        vpc_security_group_ids       = ["private"]
        vpc_security_group_ids       = ["private_web"]
      }
      lb_target_groups = {
        pb-http-8080 = {
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
        pv-http-8080 = {
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
      tags = {
        component        = "web"
        description      = "${local.environment} oasys web"
        environment-name = terraform.workspace
        monitored        = true
        os-type          = "Linux"
        os-major-version = 7
        os-version       = "RHEL 7.9"
        "Patch Group"    = "RHEL"
        server-type      = "oasys-web"
      }
    }
  }
}
