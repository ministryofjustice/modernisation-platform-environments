locals {

  # baseline presets config
  preproduction_baseline_presets_options = {}

  # baseline config
  preproduction_config = {

    baseline_acm_certificates = {
      remote_desktop_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.preproduction.hmpps-domain.service.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {

      pp-rds-2012 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "base_windows_server_2012_r2_release*"
          availability_zone             = ["eu-west-2a", "eu-west-2b"] # match load balancer config
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
          max_size         = 2
        })
        tags = {
          description = "Windows Server 2012 for testing"
          os-type     = "Windows"
          component   = "test"
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
      pp-rds-1-b = merge(local.rds_ec2_instance, {
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
          pp-rdgw-1-http = merge(local.rds_target_groups.http, {
            attachments = [
              { ec2_instance_name = "pp-rdgw-1-a" },
            ]
          })
          pp-rds-1-https = merge(local.rds_target_groups.https, {
            attachments = [
              { ec2_instance_name = "pp-rds-1-b" },
            ]
          })
        }
        listeners = {
          http = local.rds_lb_listeners.http
          https = merge(local.rds_lb_listeners.https, {
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
