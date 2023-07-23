locals {
  test_config = {

    baseline_s3_buckets = {

      # the shared image builder bucket is just created in test
      nomis-combined-reporting-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
      nomis-combined-reporting-bip-packages = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsReadOnlyAccessBucketPolicy
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_acm_certificates = {
      nomis_combined_reporting_wildcard_cert = {
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
        ]
        tags = {
          description = "Wildcard certificate for the ${local.environment} environment"
        }
      }
    }

    baseline_ssm_parameters = {
      # T1
      "tomcat"          = local.tomcat_ssm_parameters
      "bip"             = local.bip_ssm_parameters
    }

    baseline_ec2_instances = {
      bi-platform-cmc = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "base_rhel_8_5_*"
          availability_zone = "${local.region}a"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type          = "t3.large",
          vpc_security_group_ids = ["private"]
        })
        autoscaling_schedules = {}
        user_data_cloud_init  = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        ebs_volumes = {
          "/dev/sdb" = { type = "gp3", size = 100 }
          "/dev/sds" = { type = "gp3", size = 100 }
        }
        route53_records = module.baseline_presets.ec2_instance.route53_records.internal_only
      }
      t1-cmc-repo-database = {
        config = merge(module.baseline_presets.ec2_instance.config.db, {
          ami_name          = "ncr_oracle_db"
          availability_zone = "${local.region}a"
        })
        instance              = module.baseline_presets.ec2_instance.instance.default_db
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
            size  = 500
            type  = "gp3"
          }
          # "/dev/sdf" = {  # DATA02
          #   label = "data"
          #   type = null
          # }
          # "/dev/sdg" = {  # DATA03
          #   label = "data"
          #   type = null
          # }
          # "/dev/sdh" = {  # DATA04
          #   label = "data"
          #   type = null
          # }
          # "/dev/sdi" = {  # DATA05
          #   label = "data"
          #   type = null
          # }
          "/dev/sdj" = { # FLASH01
            label = "flash"
            type  = "gp3"
            size  = 50
          }
          # "/dev/sdk" = { # FLASH02
          #   label = "flash"
          #   type = null
          # }
          "/dev/sds" = {
            label = "swap"
            type  = "gp3"
            size  = 2
          }
        }
        ebs_volume_config = {
          data = {
            iops       = 3000
            type       = "gp3"
            throughput = 125
            total_size = 200
          }
          flash = {
            iops       = 3000
            type       = "gp3"
            throughput = 125
            total_size = 50
          }
        }
        route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
        # Example target group setup below
        lb_target_groups = {}
        tags = {
          component                               = "cms"
          os-type                                 = "Linux"
          os-major-version                        = 8
          os-version                              = "RHEL 8.5"
          licence-requirements                    = "Oracle Database"
          "Patch Group"                           = "RHEL"
          server-type                             = "ncr-db"
          description                             = "${local.environment} ${local.application_name} database"
          monitored                               = true
          "${local.application_name}-environment" = local.environment
          environment-name                        = terraform.workspace # used in provisioning script to select group vars
        }
      }
    }
    
    baseline_ec2_autoscaling_groups = {

      tomcat = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "base_rhel_8_5_*"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type          = "t3.large",
          vpc_security_group_ids = ["private"]
        })
        ebs_volumes = {
          "/dev/sdb" = { type = "gp3", size = 100 }
          "/dev/sds" = { type = "gp3", size = 100 }
        }
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        # autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing SAP tomcat installation"
          ami         = "base_rhel_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "ncr-tomcat"
        }
        lb_target_groups = {
          admin = {
            port                 = 7010
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7777
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }
          redirect = {
            port                 = 8443
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 8443
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }
          shutdown = {
            port                 = 8005
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 8005
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }

        }
      }

      bi-platform = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "base_rhel_8_5_*"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type          = "t3.large",
          vpc_security_group_ids = ["private"]
        })
        ebs_volumes = {
          "/dev/sdb" = { type = "gp3", size = 100 }
          "/dev/sds" = { type = "gp3", size = 100 }
        }
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        # autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing BIP 4.3 installation and connections with official RedHat RHEL8.5 image"
          ami         = "base_rhel_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "ncr-bip"
        }
        lb_target_groups = {
          http = {
            port                 = 7777
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7777
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }
          sia = {
            port                 = 6410
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 6410
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }
          cms = {
            port                 = 6400
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 6400
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }
        }
      }
    }
    baseline_lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destrroy_bucket    = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups          = ["private"]
        listeners = {
          http = {
            port     = 80
            protocol = "HTTP"
            default_action = {
              type = "redirect"
              redirect = {
                port        = "443"
                protocol    = "HTTPS"
                status_code = "HTTP_301"
              }
            }
          }
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["nomis_combined_reporting_wildcard_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "HTTPS"
                status_code  = "200"
              }
            }
          }
        }
      }
    }
    baseline_route53_zones = {
      (module.environment.domains.public.modernisation_platform) = {
        lb_alias_records = [
          { name = "web.test.${local.application_name}", type = "A", lbs_map_key = "private" }
        ]
      }
    }
  }
}
