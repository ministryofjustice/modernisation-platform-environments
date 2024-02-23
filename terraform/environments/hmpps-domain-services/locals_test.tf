locals {

  # baseline presets config
  test_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        hmpps_domain_services_pagerduty = "hmpps_domain_services_nonprod_alarms"
      }
    }
  }

  # baseline config
  test_config = {

    baseline_secretsmanager_secrets = {
      "/microsoft/AD/azure.noms.root" = local.domain_secretsmanager_secrets
    }

    baseline_acm_certificates = {
      remote_desktop_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.test.hmpps-domain.service.justice.gov.uk",
          "hmppgw1.justice.gov.uk",
          "*.hmppgw1.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {
      test-win-2012 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "base_windows_server_2012_r2_release*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["SSMPolicy"])
          user_data_raw                 = base64encode(file("./templates/user-data-pwsh.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2012 for connecting to Azure domain"
          os-type     = "Windows"
          component   = "test"
          server-type = "HmppsDomainServicesTest"
        }
      }

      test-win-2022 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2024-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["SSMPolicy"])
          user_data_raw                 = base64encode(file("./templates/user-data-pwsh.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 for connecting to Azure domain"
          os-type     = "Windows"
          component   = "test"
          server-type = "HmppsDomainServicesTest"
        }
      }
    }

    baseline_ec2_instances = {
      test-rdgw-1-a = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone = "eu-west-2a"
          user_data_raw     = base64encode(file("./templates/user-data-pwsh.yaml"))
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Gateway for azure.noms.root domain"
          server-type = "RDGateway"
        })
      })
    }

    baseline_lbs = {
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

    baseline_route53_zones = {
      "test.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}

