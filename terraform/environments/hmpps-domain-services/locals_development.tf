locals {

  # baseline presets config
  development_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        hmpps_domain_services_pagerduty = "hmpps_domain_services_nonprod_alarms"
      }
    }
  }

  # baseline config
  development_config = {

    baseline_acm_certificates = {
      remote_desktop_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.development.hmpps-domain.service.justice.gov.uk",
          "hmppgw2.justice.gov.uk",
          "*.hmppgw2.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {

      dev-win-2012 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "base_windows_server_2012_r2_release*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
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
        }
      }

      dev-win-2022 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2024-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/rds-gateway-user-data.yaml"))
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["SSMPolicy", "PatchBucketAccessPolicy"])
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
        }
      }

      dev-rhel85 = {
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
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "RHEL8.5 for connection to Azure domain"
          ami         = "hmpps_domain_services_rhel_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "hmpps-domain-services"
        }
      }
    }

    baseline_lbs = {
      public = merge(local.rds_lbs.public, {
        instance_target_groups = {
          http1 = merge(local.rds_target_groups.http, {
            attachments = [
            ]
          })
          https1 = merge(local.rds_target_groups.https, {
            attachments = [
            ]
          })
        }
        listeners = {
          http = local.rds_lb_listeners.http
          https = merge(local.rds_lb_listeners.https, {
            rules = {
            }
          })
        }
      })
    }

    baseline_route53_zones = {
      "development.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}
