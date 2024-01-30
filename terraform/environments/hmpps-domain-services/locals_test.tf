locals {

  # baseline presets config
  test_baseline_presets_options = {}

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
    }

    baseline_ec2_instances = {
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
      "test.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }

    fsx_common_parameters = {
      subnet_ids = module.environment.subnets["private"].ids
    }

    fsx_parameters = {
      automatic_backup_retention_days    = 7
      common_name                        = module.environment.environment
      copy_tags_to_backups               = false
      daily_automatic_backup_start_time  = "03:00"
      deployment_type                    = "MULTI_AZ_1"
      filesystem_name                    = "${module.environment.business_unit}-${module.environment.environment}"
      storage_capacity                   = 32 # GiB // these values can be changed
      throughput_capacity                = 8 # MB/s // these values can be changed
    }
  }
}

