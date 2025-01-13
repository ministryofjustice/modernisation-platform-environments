locals {

  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "oasys-national-reporting-production"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    # Instance Type Defaults for production
    # instance_type_defaults = {
    #   web = "m6i.2xlarge" # 8 vCPUs, 32GB RAM x 2 instances
    #   boe = "m4.2xlarge" # 8 vCPUs, 32GB RAM x 2 instances
    #   bods = "r4.2xlarge" # 8 vCPUs, 61GB RAM x 2 instance, NOT CONFIRMED as pre-prod usage may not warrant this high spec
    # }

    acm_certificates = {
      oasys_national_reporting_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.oasys-national-reporting.hmpps-production.modernisation-platform.service.justice.gov.uk",
          "reporting.oasys.service.justice.gov.uk",
          "*.reporting.oasys.service.justice.gov.uk",
          "onr.oasys.az.justice.gov.uk",
        ]
        tags = {
          description = "Wildcard certificate for the ${local.environment} environment"
        }
      }
    }

    fsx_windows = {

      pd-bods-win-share = {
        preferred_availability_zone = "eu-west-2a"
        deployment_type             = "MULTI_AZ_1"
        security_groups             = ["bods"]
        skip_final_backup           = true
        storage_capacity            = 600
        throughput_capacity         = 8

        subnets = [
          {
            name               = "private"
            availability_zones = ["eu-west-2a", "eu-west-2b"]
          }
        ]

        self_managed_active_directory = {
          dns_ips = [
            module.ip_addresses.azure_fixngo_ip.PCMCW0011,
            module.ip_addresses.azure_fixngo_ip.PCMCW0012,
          ]
          domain_name                      = "azure.hmpp.root"
          username                         = "svc_fsx_windows"
          password_secret_name             = "/sap/bods/pd/passwords"
          file_system_administrators_group = "Domain Join"
        }
        tags = {
          backup = true
        }
      }
    }

    route53_zones = {
      "reporting.oasys.service.justice.gov.uk" = {
        ns_records = [
          # use this if NS records can be pulled from terrafrom, otherwise use records variable
          { name = "production", ttl = "86400", zone_name = "production.reporting.oasys.service.justice.gov.uk" }
        ]
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-1298.awsdns-34.org", "ns-1591.awsdns-06.co.uk", "ns-317.awsdns-39.com", "ns-531.awsdns-02.net"] },
          { name = "test", type = "NS", ttl = "86000", records = ["ns-1440.awsdns-52.org", "ns-1823.awsdns-35.co.uk", "ns-43.awsdns-05.com", "ns-893.awsdns-47.net"] },
          { name = "preproduction", type = "NS", ttl = "86400", records = ["ns-1161.awsdns-17.org", "ns-2014.awsdns-59.co.uk", "ns-487.awsdns-60.com", "ns-919.awsdns-50.net"] },
        ]
      }
      "production.reporting.oasys.service.justice.gov.uk" = {
      }
    }
    secretsmanager_secrets = {
      "/sap/bods/pd"             = local.secretsmanager_secrets.bods
      "/sap/bip/pd"              = local.secretsmanager_secrets.bip
      "/oracle/database/PDBOSYS" = local.secretsmanager_secrets.db
      "/oracle/database/PDBOAUD" = local.secretsmanager_secrets.db
    }
  }
}
