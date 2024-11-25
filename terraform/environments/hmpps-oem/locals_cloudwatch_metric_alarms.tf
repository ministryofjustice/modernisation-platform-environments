locals {

  # these should match the alarms configured in ansible collectd-endpoint-monitoring role on the given EC2
  # format for each dict item is: alarm-postfix = [metric-dimension, is_https, sns_topic]
  endpoint_alarms = {
    development = {
    }
    test = {
      hmppgw1-rdgateway = ["hmppgw1.justice.gov.uk", true, "azure-fixngo-pagerduty"]
      nomis-t1          = ["c-t1.test.nomis.service.justice.gov.uk", true, "nomis-pagerduty"]
      nomis-t2          = ["c-t2.test.nomis.service.justice.gov.uk", true, "nomis-pagerduty"]
      nomis-t3          = ["c-t3.test.nomis.service.justice.gov.uk", true, "nomis-pagerduty"]
      oasys-t1          = ["t1-int.oasys.service.justice.gov.uk", true, "oasys-pagerduty"]
      oasys-t2          = ["t2-int.oasys.service.justice.gov.uk", true, "oasys-pagerduty"]
      offloc-stage      = ["stage.offloc.service.justice.gov.uk", true, "azure-fixngo-pagerduty"]
      rdgateway         = ["rdgateway1.test.hmpps-domain.service.justice.gov.uk", true, "hmpps-domain-services-pagerduty"]
    }
    preproduction = {
      cafmtx-pp          = ["cafmtx.pp.planetfm.service.justice.gov.uk", true, "planetfm-pagerduty"]
      cafmwebx-pp        = ["cafmwebx.pp.planetfm.service.justice.gov.uk", true, "planetfm-pagerduty"]
      csr-traina         = ["traina.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r1-pp          = ["r1.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r2-pp          = ["r2.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r3-pp          = ["r3.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r4-pp          = ["r4.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r5-pp          = ["r5.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r6-pp          = ["r6.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      hpa-preprod        = ["hpa-preprod.service.hmpps.dsd.io", true, "azure-fixngo-pagerduty"]
      nomis-lsast        = ["c.lsast-nomis.az.justice.gov.uk", true, "nomis-pagerduty"]
      nomis-pp           = ["c.pp-nomis.az.justice.gov.uk", true, "nomis-pagerduty"]
      nomis-reporting-pp = ["reporting.pp-nomis.az.justice.gov.uk", true, "nomis-combined-reporting-pagerduty"]
      oasys-pp           = ["pp-oasys.az.justice.gov.uk", true, "oasys-pagerduty"]
      onr-pp             = ["onr.pp-oasys.az.justice.gov.uk", true, "oasys-national-reporting-pagerduty"]
      rdgateway          = ["rdgateway1.preproduction.hmpps-domain.service.justice.gov.uk", true, "hmpps-domain-services-pagerduty"]
    }

    production = {
      bridge-oasys           = ["bridge-oasys.az.justice.gov.uk", true, "oasys-pagerduty"]
      cafmtrainweb           = ["cafmtrainweb.az.justice.gov.uk", true, "planetfm-pagerduty"]
      cafmtx                 = ["cafmtx.planetfm.service.justice.gov.uk", true, "planetfm-pagerduty"]
      cafmwebx2              = ["cafmwebx2.az.justice.gov.uk", true, "planetfm-pagerduty"]
      csr-r1                 = ["r1.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r2                 = ["r2.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r3                 = ["r3.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r4                 = ["r4.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r5                 = ["r5.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r6                 = ["r6.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      hpa                    = ["hpa.service.hmpps.dsd.io", true, "azure-fixngo-pagerduty"]
      hmpps-az-gw1-rdgateway = ["hmpps-az-gw1.justice.gov.uk", true, "azure-fixngo-pagerduty"]
      nomis                  = ["c.nomis.az.justice.gov.uk", true, "nomis-pagerduty"]
      nomis-reporting        = ["reporting.nomis.az.justice.gov.uk", true, "nomis-combined-reporting-pagerduty"]
      oasys                  = ["oasys.az.justice.gov.uk", true, "oasys-pagerduty"]
      oasys-practice         = ["practice.oasys.az.justice.gov.uk", true, "oasys-pagerduty"]
      oasys-training         = ["training.oasys.az.justice.gov.uk", true, "oasys-pagerduty"]
      offloc                 = ["www.offloc.service.justice.gov.uk", true, "azure-fixngo-pagerduty"]
      onr                    = ["onr.oasys.az.justice.gov.uk", true, "oasys-national-reporting-pagerduty"]
      rdgateway              = ["rdgateway1.hmpps-domain.service.justice.gov.uk", true, "hmpps-domain-services-pagerduty"]
    }
  }

  cloudwatch_metric_alarms_endpoint_monitoring_endpoint = {
    for key, value in local.endpoint_alarms[local.environment] : "endpoint-down-${key}" => merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"],
      {
        dimensions = {
          type          = "exitcode"
          type_instance = value[0]
        }
        alarm_actions = [value[2]]
        ok_actions    = [value[2]]
      }
    )
  }
  cloudwatch_metric_alarms_endpoint_monitoring_cert_expiry = {
    for key, value in local.endpoint_alarms[local.environment] : "endpoint-cert-expires-soon-${key}" => merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-cert-expires-soon"],
      {
        dimensions = {
          type          = "exitcode"
          type_instance = value[0]
        }
        alarm_actions = [value[2]]
        ok_actions    = [value[2]]
      }
    ) if value[1] == true
  }

  cloudwatch_metric_alarms_endpoint_monitoring = merge(
    local.cloudwatch_metric_alarms_endpoint_monitoring_endpoint,
    local.cloudwatch_metric_alarms_endpoint_monitoring_cert_expiry
  )
}
