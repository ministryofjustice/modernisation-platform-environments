locals {

  # these should match the alarms configured in ansible collectd-endpoint-monitoring role on the given EC2
  cloudwatch_metric_alarms_endpoint_status_environment_specific = {
    "development" = {
    }

    "test" = {
      "endpoint-down-nomis-t1" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "c-t1.test.nomis.service.justice.gov.uk"
        }
      })

      "endpoint-down-nomis-t2" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "c-t2.test.nomis.service.justice.gov.uk"
        }
      })

      "endpoint-down-nomis-t3" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "c-t3.test.nomis.service.justice.gov.uk"
        }
      })

      "endpoint-down-oasys-t1" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "t1-int.oasys.service.justice.gov.uk"
        }
      })

      "endpoint-down-oasys-t2" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "t2-int.oasys.service.justice.gov.uk"
        }
      })

      "endpoint-down-offloc-stage" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "stage.offloc.service.justice.gov.uk"
        }
      })

      "endpoint-down-hmppgw1-rdgateway" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "hmppgw1.justice.gov.uk"
        }
      })
    }

    "preproduction" = {
    }

    "production" = {
    }
  }

  cloudwatch_metric_alarms_endpoint_monitoring = merge(
    local.cloudwatch_metric_alarms_endpoint_status_environment_specific[local.environment], {
      "endpoint-cert-expires-soon" = module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-cert-expires-soon"]
    }
  )
}
