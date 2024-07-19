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
      dev-win-2022 = merge(local.ec2_autoscaling_groups.base_windows, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_windows.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.base_windows.config, {
          ami_name      = "hmpps_windows_server_2022_release_2024-*"
          user_data_raw = base64encode(file("./templates/rds-gateway-user-data.yaml"))
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        instance = merge(local.ec2_autoscaling_groups.base_windows.instance, {
          instance_type = "t3.medium"
        })
        tags = merge(local.ec2_autoscaling_groups.base_windows.tags, {
          description = "Windows Server 2022 for connecting to Azure domain"
        })
      })

      dev-rhel85 = merge(local.ec2_autoscaling_groups.base_linux, {
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
          ami         = "hmpps_rhel_8_5"
          description = "RHEL8.5 for connection to Azure domain"
        })
      })
    }

    ec2_instances = {
      pp-rdgw-1-a = merge(local.ec2_instances.rdgw, {
        config = merge(local.ec2_instances.rdgw.config, {
          availability_zone = "eu-west-2a"
          user_data_raw     = base64encode(file("./templates/windows_server_2022-user-data.yaml")) # TODO
        })
        tags = merge(local.ec2_instances.rdgw.tags, {
          description = "Remote Desktop Gateway for azure.hmpp.root domain"
          # server-type = "RDGateway" # TODO
        })
      })
      pp-rds-1-a = merge(local.ec2_instances.rds, {
        config = merge(local.ec2_instances.rds.config, {
          availability_zone         = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.rds.config.instance_profile_policies, ["SSMPolicy", "PatchBucketAccessPolicy"])
          user_data_raw             = base64encode(file("./templates/user-data-domain-join.yaml"))
        })
        tags = merge(local.ec2_instances.rds.tags, {
          description = "Remote Desktop Services for azure.hmpp.root domain"
        })
      })
    }

    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          pp-rdgw-1-http = merge(local.lbs.public.instance_target_groups.http, {
            attachments = [
              { ec2_instance_name = "pp-rdgw-1-a" },
            ]
          })
          pp-rds-1-https = merge(local.lbs.public.instance_target_groups.https, {
            attachments = [
              { ec2_instance_name = "pp-rds-1-a" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
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
        })
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
