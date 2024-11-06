locals {

  endpoint_down_alarm = module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"]

  # these should match the alarms configured in ansible collectd-endpoint-monitoring role on the given EC2
  cloudwatch_metric_alarms_endpoint_status_environment_specific = {
    "development" = {
    }

    "test" = {
      "endpoint-down-nomis-t1" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "c-t1.test.nomis.service.justice.gov.uk"
        }
      })

      "endpoint-down-nomis-t2" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "c-t2.test.nomis.service.justice.gov.uk"
        }
      })

      "endpoint-down-nomis-t3" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "c-t3.test.nomis.service.justice.gov.uk"
        }
      })

      "endpoint-down-oasys-t1" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "t1-int.oasys.service.justice.gov.uk"
        }
      })

      "endpoint-down-oasys-t2" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "t2-int.oasys.service.justice.gov.uk"
        }
      })

      "endpoint-down-offloc-stage" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "stage.offloc.service.justice.gov.uk"
        }
      })

      "endpoint-down-hmppgw1-rdgateway" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "hmppgw1.justice.gov.uk"
        }
      })
    }

    "preproduction" = {
      "endpoint-down-nomis-pp" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "c.pp-nomis.az.justice.gov.uk"
        }
      })

      "endpoint-down-nomis-lsast" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "c.lsast-nomis.az.justice.gov.uk"
        }
      })

      "endpoint-down-oasys-pp" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "pp-oasys.az.justice.gov.uk"
        }
      })

      "endpoint-down-onr-pp" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "onr.pp-oasys.az.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r1-pp" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r1.pp.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r2-pp" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r2.pp.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r3-pp" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r3.pp.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r4-pp" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r4.pp.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r5-pp" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r5.pp.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r6-pp" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r6.pp.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-traina" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "traina.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-cafmwebx-pp" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "cafmwebx.pp.planetfm.service.justice.gov.uk"
        }
        alarm_actions = [] # TODO: remove when IP allow listing fixed
        ok_actions    = []
      })

      "endpoint-down-hpa-preprod" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "hpa-preprod.service.hmpps.dsd.io"
        }
        alarm_actions = [] # TODO: remove when IP allow listing fixed
        ok_actions    = []
      })
    }


    "production" = {
      "endpoint-down-nomis" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "c.nomis.az.justice.gov.uk"
        }
      })

      "endpoint-down-nomis-reporting" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "reporting.nomis.az.justice.gov.uk"
        }
      })

      "endpoint-down-oasys" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "oasys.az.justice.gov.uk"
        }
        alarm_actions = [] # TODO: remove when IP allow listing fixed
        ok_actions    = []
      })

      "endpoint-down-oasys-training" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "training.oasys.az.justice.gov.uk"
        }
      })

      "endpoint-down-oasys-practice" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "practice.oasys.az.justice.gov.uk"
        }
      })

      "endpoint-down-bridge-oasys" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "bridge-oasys.az.justice.gov.uk"
        }
      })

      "endpoint-down-onr" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "onr.oasys.az.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r1" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r1.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r2" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r2.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r3" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r3.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r4" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r4.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r5" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r5.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-csr-r6" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "r6.csr.service.justice.gov.uk"
        }
      })

      "endpoint-down-cafmwebx2" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "cafmwebx2.az.justice.gov.uk"
        }
        alarm_actions = [] # TODO: remove when IP allow listing fixed
        ok_actions    = []
      })

      "endpoint-down-cafmtrainweb" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "cafmtrainweb.az.justice.gov.uk"
        }
      })

      "endpoint-down-offloc" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "www.offloc.service.justice.gov.uk"
        }
        alarm_actions = [] # TODO: remove when IP allow listing fixed
        ok_actions    = []
      })

      "endpoint-down-hpa" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "hpa.service.hmpps.dsd.io"
        }
        alarm_actions = [] # TODO: remove when IP allow listing fixed
        ok_actions    = []
      })

      "endpoint-down-hmpps-az-gw1-rdgateway" = merge(local.endpoint_down_alarm, {
        dimensions = {
          type          = "exitcode"
          type_instance = "hmpps-az-gw1.justice.gov.uk"
        }
      })
    }
  }

  cloudwatch_metric_alarms_endpoint_monitoring = merge(
    local.cloudwatch_metric_alarms_endpoint_status_environment_specific[local.environment], {
      "endpoint-cert-expires-soon" = module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-cert-expires-soon"]
    }
  )
}
