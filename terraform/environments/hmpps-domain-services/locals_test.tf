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
          # clean up Computer and DNS entry from azure.noms.root domain before using
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.base_windows.config, {
          ami_name = "hmpps_windows_server_2022_release_2024-*"
          user_data_raw = base64encode(templatefile(
            "../../modules/baseline_presets/ec2-user-data/user-data-pwsh.yaml.tftpl", {
              branch = "TM-153/remote-desktop-automation"
            }
          ))
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        instance = merge(local.ec2_autoscaling_groups.base_windows.instance, {
          instance_type = "t3.large"
        })
        lb_target_groups = {
          http = local.lbs.public.instance_target_groups.http
        }
        tags = merge(local.ec2_autoscaling_groups.base_windows.tags, {
          description = "Windows Server 2022 instance for testing domain join and patching"
          domain-name = "azure.noms.root"
        })
      })

      test-rdgw-2-a = merge(local.ec2_autoscaling_groups.base_windows, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_windows.autoscaling_group, {
          # clean up Computer and DNS entry from azure.noms.root domain before using
          desired_capacity = 1
          initial_lifecycle_hooks = {
            "ready-hook" = {
              default_result       = "ABANDON"
              heartbeat_timeout    = 2700 # 45 minutes
              lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
            }
          }
        })
        config = merge(local.ec2_autoscaling_groups.base_windows.config, {
          ami_name = "hmpps_windows_server_2022_release_2024-*"
          user_data_raw = base64encode(templatefile(
            "../../modules/baseline_presets/ec2-user-data/user-data-pwsh-asg-ready-hook.yaml.tftpl", {
              branch = "TM-153/remote-desktop-automation"
            }
          ))
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        instance = merge(local.ec2_autoscaling_groups.base_windows.instance, {
          instance_type = "t3.large"
        })
        lb_target_groups = {
          http = local.lbs.public.instance_target_groups.http
        }
        tags = merge(local.ec2_autoscaling_groups.base_windows.tags, {
          description = "Windows Server 2022 instance for testing domain join and patching"
          domain-name = "azure.noms.root"
          server-type = "RDGateway"
        })
      })
    }

    ec2_instances = {
      test-rdgw-1-a = merge(local.ec2_instances.rdgw, {
        config = merge(local.ec2_instances.rdgw.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = [
            "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
          ]
        })
        tags = merge(local.ec2_instances.rdgw.tags, {
          description = "Remote Desktop Gateway for azure.noms.root domain"
          domain-name = "azure.noms.root"
        })
      })
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
              test-rdgw-2-http = {
                priority = 150
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rdgw-2-a-http"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdgateway2.test.hmpps-domain.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        })
      })
    }

    route53_zones = {
      "test.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdgateway2", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/microsoft/AD/azure.noms.root" = local.secretsmanager_secrets.domain
    }
  }
}

