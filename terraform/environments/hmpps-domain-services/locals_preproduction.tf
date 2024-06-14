locals {

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          hmpps_domain_services_pagerduty = "hmpps_domain_services_prod_alarms"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    acm_certificates = {
      remote_desktop_and_planetfm_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.hmpps-domain-services.hmpps-preproduction.modernisation-platform.service.justice.gov.uk",
          "*.preproduction.hmpps-domain.service.justice.gov.uk",
          "*.pp.planetfm.service.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
    }

    ec2_autoscaling_groups = {
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
          ami         = "hmpps_rhel_8_5"
          os-type     = "Linux"
          component   = "test"
        }
      }
    }

    ec2_instances = {
      pp-rdgw-1-a = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone         = "eu-west-2a"
          instance_profile_policies = concat(local.rds_ec2_instance.config.instance_profile_policies, ["SSMPolicy", "PatchBucketAccessPolicy"])
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Gateway for azure.hmpp.root domain"
        })
      })
      pp-rds-1-a = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone         = "eu-west-2a"
          instance_profile_policies = concat(local.rds_ec2_instance.config.instance_profile_policies, ["SSMPolicy", "PatchBucketAccessPolicy"])
          user_data_raw             = base64encode(file("./templates/user-data-domain-join.yaml"))
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Services for azure.hmpp.root domain"
        })
      })
    }

    lbs = {
      public = merge(local.rds_lbs.public, {
        instance_target_groups = {
          pp-rdgw-1-http = merge(local.rds_target_groups.http, {
            attachments = [
              { ec2_instance_name = "pp-rdgw-1-a" },
            ]
          })
          pp-rds-1-https = merge(local.rds_target_groups.https, {
            attachments = [
              { ec2_instance_name = "pp-rds-1-a" },
            ]
          })
        }
        listeners = {
          http = local.rds_lb_listeners.http
          https = merge(local.rds_lb_listeners.https, {
            certificate_names_or_arns = ["remote_desktop_and_planetfm_wildcard_cert"]
            rules = {
              pp-rdgw-1-http = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-rdgw-1-http"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdgateway1.preproduction.hmpps-domain.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              pp-rds-1-https = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-rds-1-https"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdweb1.preproduction.hmpps-domain.service.justice.gov.uk",
                      "cafmtx.pp.planetfm.service.justice.gov.uk",
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
      "preproduction.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}
