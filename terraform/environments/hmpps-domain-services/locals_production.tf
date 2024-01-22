locals {

  # baseline presets config
  production_baseline_presets_options = {}

  # baseline config
  production_config = {

    baseline_secretsmanager_secrets = {
      "/microsoft/AD/azure.hmpp.root" = local.domain_secretsmanager_secrets
    }

    baseline_acm_certificates = {
      remote_desktop_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.hmpps-domain.service.justice.gov.uk",
          "hmpps-az-gw1.justice.gov.uk",
          "*.hmpps-az-gw1.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
    }

    baseline_ec2_instances = {
      pd-rdgw-1-a = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone = "eu-west-2a"
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Gateway for hmpp.noms.root domain"
        })
      })
      pd-rdgw-1-b = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone = "eu-west-2b"
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Gateway for hmpp.noms.root domain"
        })
      })
      pd-rds-1-a = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone = "eu-west-2a"
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Services for hmpp.noms.root domain"
        })
      })
    }

    baseline_lbs = {
      public = merge(local.rds_lbs.public, {
        instance_target_groups = {
          pd-rdgw-1-http = merge(local.rds_target_groups.http, {
            attachments = [
              { ec2_instance_name = "pd-rdgw-1-a" },
              { ec2_instance_name = "pd-rdgw-1-b" },
            ]
          })
          pd-rds-1-https = merge(local.rds_target_groups.https, {
            attachments = [
              { ec2_instance_name = "pd-rds-1-a" },
            ]
          })
        }
        listeners = {
          http = local.rds_lb_listeners.http
          https = merge(local.rds_lb_listeners.https, {
            rules = {
              pd-rdgw-1-http = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-rdgw-1-http"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdgateway1.hmpps-domain.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              pd-rds-1-https = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-rds-1-https"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdweb1.hmpps-domain.service.justice.gov.uk",
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
      "hmpps-domain.service.justice.gov.uk" = {
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-1447.awsdns-52.org", "ns-1826.awsdns-36.co.uk", "ns-1022.awsdns-63.net", "ns-418.awsdns-52.com", ] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-134.awsdns-16.com", "ns-1426.awsdns-50.org", "ns-1934.awsdns-49.co.uk", "ns-927.awsdns-51.net", ] },
          { name = "preproduction", type = "NS", ttl = "86400", records = ["ns-1509.awsdns-60.org", "ns-1925.awsdns-48.co.uk", "ns-216.awsdns-27.com", "ns-753.awsdns-30.net", ] },
        ]

        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}
