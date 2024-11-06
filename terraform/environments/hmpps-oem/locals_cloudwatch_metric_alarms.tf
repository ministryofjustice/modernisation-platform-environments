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
      "endpoint-down-nomis-pp" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "c.pp-nomis.az.justice.gov.uk"
        }
      })
      "endpoint-down-nomis-lsast" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "c.lsast-nomis.az.justice.gov.uk"
        }
      })
      "endpoint-down-oasys-pp" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "pp-oasys.az.justice.gov.uk"
        }
      })
      "endpoint-down-onr-pp" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "onr.pp-oasys.az.justice.gov.uk"
        }
      })
      "endpoint-down-csr-r1-pp" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "r1.pp.csr.service.justice.gov.uk"
        }
      })
      "endpoint-down-csr-r2-pp" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "r2.pp.csr.service.justice.gov.uk"
        }
      })
      "endpoint-down-csr-r3-pp" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "r3.pp.csr.service.justice.gov.uk"
        }
      })
      "endpoint-down-csr-r4-pp" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "r4.pp.csr.service.justice.gov.uk"
        }
      })
      "endpoint-down-csr-r5-pp" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "r5.pp.csr.service.justice.gov.uk"
        }
      })
      "endpoint-down-csr-r6-pp" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "r6.pp.csr.service.justice.gov.uk"
        }
      })
      "endpoint-down-csr-traina" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "traina.csr.service.justice.gov.uk"
        }
      })
      "endpoint-down-cafmwebx-pp" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "cafmwebx.pp.planetfm.service.justice.gov.uk"
        }
        alarm_actions = [] # TODO: remove when IP allow listing fixed
        ok_actions    = []
      })
      "endpoint-down-hpa-preprod" = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"], {
        dimensions = {
          type          = "exitcode"
          type_instance = "hpa-preprod.service.hmpps.dsd.io"
        }
        alarm_actions = [] # TODO: remove when IP allow listing fixed
        ok_actions    = []
      })
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
