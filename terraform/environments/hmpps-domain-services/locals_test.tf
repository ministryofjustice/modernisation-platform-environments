locals {

  baseline_presets_test = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "hmpps-domain-services-test"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    acm_certificates = {
      remote_desktop_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.hmpps-domain-services.hmpps-test.modernisation-platform.service.justice.gov.uk",
          "*.test.hmpps-domain.service.justice.gov.uk",
          "hmppgw1.justice.gov.uk",
          "*.hmppgw1.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
    }

    ec2_autoscaling_groups = {
      test-rhel85 = merge(local.ec2_autoscaling_groups.base_linux, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_linux.autoscaling_group, {
          # clean up Computer and DNS entry from azure.noms.root domain before using
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.base_linux.config, {
          ami_name = "base_rhel_8_5*"
        })
        instance = merge(local.ec2_autoscaling_groups.base_linux.instance, {
          instance_type = "t3.medium"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.base_linux.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.base_linux.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.base_linux.tags, {
          ami         = "rhel_8_5"
          description = "RHEL 8.5 instance for testing domain join and patching"
          domain-name = "azure.noms.root"
        })
      })

      test-win-2012 = merge(local.ec2_autoscaling_groups.base_windows, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_windows.autoscaling_group, {
          # clean up Computer and DNS entry from azure.noms.root domain before using
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.base_windows.config, {
          ami_name = "base_windows_server_2012_r2_release*"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_autoscaling_groups.base_windows.instance, {
          instance_type = "t3.medium"
        })
        tags = merge(local.ec2_autoscaling_groups.base_windows.tags, {
          description = "Windows Server 2012 for connecting to Azure domain"
          domain-name = "azure.noms.root"
        })
      })

      test-win-2022 = merge(local.ec2_autoscaling_groups.base_windows, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_windows.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.base_windows.config, {
          ami_name = "hmpps_windows_server_2022_release_2024-*"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        instance = merge(local.ec2_autoscaling_groups.base_windows.instance, {
          instance_type = "t3.medium"
        })
        tags = merge(local.ec2_autoscaling_groups.base_windows.tags, {
          description = "Windows Server 2022 instance for testing domain join and patching"
          domain-name = "azure.noms.root"
        })
      })

      # RDGW/RDS infra can be build as ASG now (1 server only for RDS)
      # test-rdgw-2-a = merge(local.ec2_autoscaling_groups.rdgw, {
      #   tags = merge(local.ec2_autoscaling_groups.rdgw.tags, {
      #     domain-name = "azure.noms.root"
      #   })
      # }
      # test-rds-2-a = merge(local.ec2_autoscaling_groups.rds, {
      #   tags = merge(local.ec2_autoscaling_groups.rds.tags, {
      #     domain-name = "azure.noms.root"
      #   })
      #   cloudwatch_metric_alarms = null
      # })
    }

    ec2_instances = {
      # NOTE: next rebuild do this as an ASG
      test-rdgw-1-a = merge(local.ec2_instances.rdgw, {
        config = merge(local.ec2_instances.rdgw.config, {
          availability_zone = "eu-west-2a"
        })
        tags = merge(local.ec2_instances.rdgw.tags, {
          description = "Remote Desktop Gateway for azure.noms.root domain"
          domain-name = "azure.noms.root"
        })
      })

      t1-jump2022-1 = merge(local.ec2_instances.jumpserver, {
        config = merge(local.ec2_instances.jumpserver.config, {
          ami_name          = "hmpps_windows_server_2022_release_2025-01-02T00-00-40.487Z"
          availability_zone = "eu-west-2a"
        })
        tags = merge(local.ec2_instances.jumpserver.tags, {
          domain-name = "azure.noms.root"
        })
      })

      # testing only do not use
      t2-jump2022-2 = merge(local.ec2_instances.jumpserver, {
        config = merge(local.ec2_instances.jumpserver.config, {
          ami_name          = "hmpps_windows_server_2022_release_2025-*"
          availability_zone = "eu-west-2b"
          user_data_raw = base64encode(templatefile(
            "../../modules/baseline_presets/ec2-user-data/user-data-pwsh.yaml.tftpl", {
              branch = "TM/TM-1080/move-rds-instances-to-their-own-ou"
            }
          ))
        })
        tags = merge(local.ec2_instances.jumpserver.tags, {
          domain-name = "azure.noms.root"
        })
        cloudwatch_metric_alarms = null
      })
      # testing only do not use
      # test-rds-2-b = merge(local.ec2_instances.rds, {
      #   config = merge(local.ec2_instances.rds.config, {
      #     ami_name          = "hmpps_windows_server_2022_release_2025-*"
      #     availability_zone = "eu-west-2b"
      #     user_data_raw = base64encode(templatefile(
      #       "../../modules/baseline_presets/ec2-user-data/user-data-pwsh.yaml.tftpl", {
      #         branch = "TM/TM-1080/move-rds-instances-to-their-own-ou"
      #       }
      #     ))
      #     instance_profile_policies = concat(local.ec2_instances.rds.config.instance_profile_policies, [
      #       "Ec2SecretPolicy"]
      #     )
      #   })
      #   tags = merge(local.ec2_instances.rds.tags, {
      #     domain-name = "azure.noms.root"
      #   })
      #   cloudwatch_metric_alarms = null
      # })
    }

    fsx_windows = {
      # test-win-fs = {
      #   subnets = [{
      #     name               = "private"
      #     availability_zones = ["eu-west-2a", "eu-west-2b"]
      #   }]
      #   preferred_subnet_name       = "private"
      #   preferred_availability_zone = "eu-west-2a"
      #   deployment_type             = "MULTI_AZ_1"
      #   security_groups             = ["rds-ec2s"]
      #   skip_final_backup           = true
      #   storage_capacity            = 32
      #   throughput_capacity         = 8
      #   self_managed_active_directory = {
      #     dns_ips = [
      #       module.ip_addresses.mp_ip.ad-azure-dc-a,
      #       module.ip_addresses.mp_ip.ad-azure-dc-b,
      #     ]
      #     domain_name          = "azure.noms.root"
      #     username             = "svc_join_domain"
      #     password_secret_name = "/microsoft/AD/azure.noms.root/shared-passwords"
      #   }
      # }
    }

    iam_policies = {
      Ec2SecretPolicy = {
        description = "Permissions required for secret value access by instances"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/microsoft/AD/azure.noms.root/shared-passwords-*",
            ]
          }
        ]
      }
    }

    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          test-rdgw-1-http = merge(local.lbs.public.instance_target_groups.http, {
            attachments = [
              { ec2_instance_name = "test-rdgw-1-a" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            alarm_target_group_names = [
              "test-rdgw-1-http",
            ]
            rules = {
              test-rdgw-1-http = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rdgw-1-http"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdgateway1.test.hmpps-domain.service.justice.gov.uk",
                      "hmppgw1.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        })
      })
    }

    schedule_alarms_lambda = {
      alarm_patterns = [
        "public-https-*-unhealthy-load-balancer-host",
        "*-instance-or-cloudwatch-agent-stopped",
      ]
    }

    route53_zones = {
      "test.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/microsoft/AD/azure.noms.root" = local.secretsmanager_secrets.domain
    }
  }
}
