locals {

  baseline_presets_test = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          hmpps_domain_services_pagerduty = "hmpps_domain_services_nonprod_alarms"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    acm_certificates = {
      remote_desktop_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
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
          description = "RHEL8.5"
          ami         = "hmpps_rhel_8_5"
          Patching    = "Yes"
        })
      })

      test-win-2012 = merge(local.ec2_autoscaling_groups.base_windows, {
        # clean up test-win-2012 Computer and DNS entry from azure.noms.root domain before using
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_windows.autoscaling_group, {
          desired_capacity = 0
        })
        autoscaling_schedules = null # TODO
        config = merge(local.ec2_autoscaling_groups.base_windows.config, {
          ami_name      = "base_windows_server_2012_r2_release*"
          user_data_raw = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_autoscaling_groups.base_windows.instance, {
          instance_type = "t3.medium"
        })
        tags = merge(local.ec2_autoscaling_groups.base_windows.tags, {
          description = "Windows Server 2012 for connecting to Azure domain"
          server-type = "HmppsDomainServicesTest"
        })
      })

      test-win-2022 = merge(local.ec2_autoscaling_groups.base_windows, {
        # clean up test-win-2022 Computer and DNS entry from azure.noms.root domain before using
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_windows.autoscaling_group, {
          desired_capacity = 0
        })
        autoscaling_schedules = null # TODO
        config = merge(local.ec2_autoscaling_groups.base_windows.config, {
          ami_name      = "hmpps_windows_server_2022_release_2024-*"
          user_data_raw = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        instance = merge(local.ec2_autoscaling_groups.base_windows.instance, {
          instance_type = "t3.medium"
        })
        tags = merge(local.ec2_autoscaling_groups.base_windows.tags, {
          description = "Windows Server 2022 for connecting to Azure domain"
          server-type = "HmppsDomainServicesTest"
          Patching    = "Yes"
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
          server-type = "RDGateway"
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

    route53_zones = {
      "test.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/microsoft/AD/azure.noms.root" = local.secretsmanager_secrets.domain
    }
  }
}

