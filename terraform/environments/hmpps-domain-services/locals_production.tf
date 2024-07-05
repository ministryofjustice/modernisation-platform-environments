locals {

  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          hmpps_domain_services_pagerduty = "hmpps_domain_services_prod_alarms"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    acm_certificates = {
      remote_desktop_wildcard_and_planetfm_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.hmpps-domain-services.hmpps-production.modernisation-platform.service.justice.gov.uk",
          "*.hmpps-domain.service.justice.gov.uk",
          "hmpps-az-gw1.justice.gov.uk",
          "*.hmpps-az-gw1.justice.gov.uk",
          "*.planetfm.service.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
    }

    ec2_instances = {
      pd-rdgw-1-a = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone         = "eu-west-2a"
          instance_profile_policies = concat(local.rds_ec2_instance.config.instance_profile_policies, ["SSMPolicy", "PatchBucketAccessPolicy"])
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Gateway for azure.hmpp.root domain"
        })
      })
      pd-rdgw-1-b = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone         = "eu-west-2b"
          instance_profile_policies = concat(local.rds_ec2_instance.config.instance_profile_policies, ["SSMPolicy", "PatchBucketAccessPolicy"])
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Gateway for azure.hmpp.root domain"
        })
      })
      pd-rds-1-a = merge(local.rds_ec2_instance, {
        config = merge(local.rds_ec2_instance.config, {
          availability_zone         = "eu-west-2a"
          instance_profile_policies = concat(local.rds_ec2_instance.config.instance_profile_policies, ["SSMPolicy", "PatchBucketAccessPolicy"])
          user_data_raw             = base64encode(file("./templates/user-data-domain-join.yaml"))
        })
        instance = merge(local.rds_ec2_instance.instance, {
          instance_type = "t3.large"
        })
        tags = merge(local.rds_ec2_instance.tags, {
          description = "Remote Desktop Services for azure.hmpp.root domain"
        })
      })
    }

    lbs = {
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
            certificate_names_or_arns = ["remote_desktop_wildcard_and_planetfm_cert"]
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
                      "cafmtx.planetfm.service.justice.gov.uk",
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
      "hmpps-domain.service.justice.gov.uk" = {
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-1447.awsdns-52.org", "ns-1826.awsdns-36.co.uk", "ns-1022.awsdns-63.net", "ns-418.awsdns-52.com", ] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-134.awsdns-16.com", "ns-1426.awsdns-50.org", "ns-1934.awsdns-49.co.uk", "ns-927.awsdns-51.net", ] },
          { name = "preproduction", type = "NS", ttl = "86400", records = ["ns-1509.awsdns-60.org", "ns-1925.awsdns-48.co.uk", "ns-216.awsdns-27.com", "ns-753.awsdns-30.net", ] },
          { name = "smtp", type = "A", ttl = 300, records = ["10.180.104.100", "10.180.105.100"] } # smtp.internal.network.justice.gov.uk not publicly resolvable
        ]

        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/microsoft/AD/azure.hmpp.root" = local.domain_secretsmanager_secrets
    }
  }
}
