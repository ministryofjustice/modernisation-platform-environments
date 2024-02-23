locals {

  # baseline presets config
  preproduction_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        hmpps_domain_services_pagerduty = "hmpps_domain_services_prod_alarms"
      }
    }
  }

  # baseline config
  preproduction_config = {

    baseline_acm_certificates = {
      remote_desktop_and_planetfm_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.preproduction.hmpps-domain.service.justice.gov.uk",
          "*.pp.planetfm.service.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
    }

    baseline_ec2_instances = {
      pp-rdgw-1-a = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone = "eu-west-2a"
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Gateway for hmpp.noms.root domain"
        })
      })
      pp-rds-1-a = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone         = "eu-west-2a"
          user_data_raw             = base64encode(file("./templates/user-data-domain-join.yaml"))
          instance_profile_policies = concat(local.rds_ec2_instance.config.instance_profile_policies, ["SSMPolicy"])
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Services for hmpp.noms.root domain"
        })
      })
    }

    baseline_lbs = {
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

    baseline_route53_zones = {
      "preproduction.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }

  }
}
