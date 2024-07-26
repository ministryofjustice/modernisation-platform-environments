locals {

  ec2_autoscaling_groups = {

    web = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
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
        subnet_name                   = "private"
      }
      instance = {
        disable_api_termination = false
        instance_type           = "t3.medium"
        key_name                = "ec2-user"
        vpc_security_group_ids  = ["private_web"]
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
          branch       = "main"
          ansible_args = ""
        }
        scripts = [ # paths are relative to templates/ dir
          "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
          "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
          "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
        ]
      }
      tags = {
        backup           = "false"
        description      = "${local.environment} oasys web"
        os-type          = "Linux"
        os-major-version = 7
        os-version       = "RHEL 7.9"
        server-type      = "oasys-web"
        update-ssm-agent = "patchgroup1"
      }
    }
  }
}
