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
      test-rhel85 = {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "base_rhel_8_5*"
          availability_zone         = null
          instance_profile_policies = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["SSMPolicy", "PatchBucketAccessPolicy"])
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        tags = {
          description = "RHEL8.5"
          ami         = "hmpps_rhel_8_5"
          os-type     = "Linux"
          component   = "test"
          Patching    = "Yes"
        }
      }

      test-win-2012 = {
        # clean up test-win-2012 Computer and DNS entry from azure.noms.root domain before using
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "base_windows_server_2012_r2_release*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["SSMPolicy", "PatchBucketAccessPolicy"])
          user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
        }
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        tags = {
          component   = "test"
          description = "Windows Server 2012 for connecting to Azure domain"
          os-type     = "Windows"
          server-type = "HmppsDomainServicesTest"
        }
      }

      test-win-2022 = {
        # clean up test-win-2022 Computer and DNS entry from azure.noms.root domain before using
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2024-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["SSMPolicy", "PatchBucketAccessPolicy"])
          user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        tags = {
          component   = "test"
          description = "Windows Server 2022 for connecting to Azure domain"
          os-type     = "Windows"
          server-type = "HmppsDomainServicesTest"
          Patching    = "Yes"
        }
      }
    }

    ec2_instances = {
      test-rdgw-1-a = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone = "eu-west-2a"
          user_data_raw     = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
        })
        tags = merge(local.rds_ec2_instance.tags, {
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
      public = merge(local.rds_lbs.public, {
        instance_target_groups = {
          test-rdgw-1-http = merge(local.rds_target_groups.http, {
            attachments = [
              { ec2_instance_name = "test-rdgw-1-a" },
            ]
          })
        }
        listeners = {
          http = local.rds_lb_listeners.http
          https = merge(local.rds_lb_listeners.https, {
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
        }
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
      "/microsoft/AD/azure.noms.root" = local.domain_secretsmanager_secrets
    }
  }
}

