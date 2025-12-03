locals {

  # these should match the alarms configured in ansible collectd-endpoint-monitoring role on the given EC2
  # format for each dict item is: alarm-postfix = [metric-dimension, is_https, sns_topic]
  endpoint_alarms = {

    development = {
    }

    test = {
      # az-noms-dev-test-environments
      offloc-stage = ["stage.offloc.service.justice.gov.uk", true, "azure-fixngo-pagerduty"]

      # hmpps-domain-services
      rdgateway = ["rdgateway1.test.hmpps-domain.service.justice.gov.uk", true, "hmpps-domain-services-pagerduty"]
      rdweb     = ["rdweb1.test.hmpps-domain.service.justice.gov.uk", true, "hmpps-domain-services-pagerduty"]

      # nomis
      nomis-t1 = ["c-t1.test.nomis.service.justice.gov.uk", true, "nomis-pagerduty"]
      nomis-t2 = ["c-t2.test.nomis.service.justice.gov.uk", true, "nomis-pagerduty"]
      nomis-t3 = ["c-t3.test.nomis.service.justice.gov.uk", true, "nomis-pagerduty"]

      # oasys
      oasys-t1 = ["t1-int.oasys.service.justice.gov.uk", true, "oasys-pagerduty"]
      oasys-t2 = ["t2-int.oasys.service.justice.gov.uk", true, "oasys-pagerduty"]
    }

    preproduction = {
      # corporate-staff-rostering - alarms disabled on request from Glenn
      #csr-r1-pp  = ["r1.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      #csr-r2-pp  = ["r2.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      #csr-r3-pp  = ["r3.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      #csr-r4-pp  = ["r4.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      #csr-r5-pp  = ["r5.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      #csr-r6-pp  = ["r6.pp.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-traina = ["traina.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]

      # hmpps-domain-services
      rdgateway = ["rdgateway1.preproduction.hmpps-domain.service.justice.gov.uk", true, "hmpps-domain-services-pagerduty"]

      # nomis
      nomis-lsast = ["c-lsast.preproduction.nomis.service.justice.gov.uk", true, "nomis-pagerduty"]
      nomis-pp    = ["c.preproduction.nomis.service.justice.gov.uk", true, "nomis-pagerduty"]

      # nomis-combined-reporting
      nomis-reporting-pp-aws   = ["preproduction.reporting.nomis.service.justice.gov.uk", true, "nomis-combined-reporting-pagerduty"]
      nomis-reporting-pp-admin = ["admin.preproduction.reporting.nomis.service.justice.gov.uk", true, "nomis-combined-reporting-pagerduty"]

      # oasys
      oasys-pp = ["pp.oasys.service.justice.gov.uk", true, "oasys-pagerduty"]

      # oasys-national-reporting
      onr-pp = ["onr.pp-oasys.az.justice.gov.uk", true, "oasys-national-reporting-pagerduty"]

      # planetfm - alarms disabled on request from Glenn
      #cafmtx-pp   = ["cafmtx.pp.planetfm.service.justice.gov.uk", true, "planetfm-pagerduty"]
      #cafmwebx-pp = ["cafmwebx.pp.planetfm.service.justice.gov.uk", true, "planetfm-pagerduty"]
    }

    production = {
      # az-noms-production-1
      hmpps-az-gw1-rdgateway = ["hmpps-az-gw1.justice.gov.uk", true, "azure-fixngo-pagerduty"]
      offloc                 = ["www.offloc.service.justice.gov.uk", true, "azure-fixngo-pagerduty"]

      # corporate-staff-rostering
      csr-r1 = ["r1.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r2 = ["r2.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r3 = ["r3.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r4 = ["r4.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r5 = ["r5.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]
      csr-r6 = ["r6.csr.service.justice.gov.uk", false, "corporate-staff-rostering-pagerduty"]

      # hmpps-domain-services
      rdgateway = ["rdgateway1.hmpps-domain.service.justice.gov.uk", true, "hmpps-domain-services-pagerduty"]

      # nomis
      nomis = ["c.nomis.az.justice.gov.uk", true, "nomis-pagerduty"]

      # nomis-combined-reporting
      nomis-reporting-aws   = ["reporting.nomis.service.justice.gov.uk", true, "nomis-combined-reporting-pagerduty"]
      nomis-reporting-admin = ["admin.reporting.nomis.service.justice.gov.uk", true, "nomis-combined-reporting-pagerduty"]

      # oasys
      oasys          = ["oasys.service.justice.gov.uk", true, "oasys-pagerduty"]
      oasys-int      = ["int.oasys.service.justice.gov.uk", true, "oasys-pagerduty"]
      oasys-practice = ["practice.int.oasys.service.justice.gov.uk", true, "oasys-pagerduty"]
      oasys-training = ["training.int.oasys.service.justice.gov.uk", true, "oasys-pagerduty"]

      # oasys-national-reporting
      onr = ["onr.oasys.az.justice.gov.uk", true, "oasys-national-reporting-pagerduty"]

      # planetfm - alarms disabled on request from Glenn
      #cafmtrainweb = ["cafmtrainweb.planetfm.service.justice.gov.uk", true, "planetfm-pagerduty"]
      #cafmtx       = ["cafmtx.planetfm.service.justice.gov.uk", true, "planetfm-pagerduty"]
      #cafmwebx2    = ["cafmwebx2.planetfm.service.justice.gov.uk", true, "planetfm-pagerduty"]
    }
  }

  cloudwatch_metric_alarms_endpoint_monitoring_endpoint = {
    for key, value in local.endpoint_alarms[local.environment] : "endpoint-down-${key}" => merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring["endpoint-down"],
      {
        evaluation_periods  = local.environment == "production" ? "1" : "3"
        datapoints_to_alarm = local.environment == "production" ? "1" : "3"
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
          type          = "gauge"
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

  # you can generate list of scheduled pipelines using script in dso-modernisation-platform-automation repo
  # e.g. src/github-workflow-monitoring/github-workflow-monitor.sh -i 3600 -n 168 -r all | grep -v all | cut -d, -f2,3 | sed 's/^/["/g' | sed 's/,/", "/g' | sed 's/$/", "dso-pipelines-pagerduty"],/g'
  gha_pipeline_alarms = [
    # [repo name, pipeline name, sns topic, optionally overwrite alarm settings]
    ["dso-certificates", "cert-renewal-devtest", "dso-pipelines-pagerduty", {}],
    ["dso-certificates", "cert-renewal-prod", "dso-pipelines-pagerduty", {}],
    ["dso-certificates", "stale", "dso-pipelines-pagerduty", {}],
    ["dso-infra-azure-ad", "application-management", "dso-pipelines-pagerduty", {}],
    ["dso-infra-azure-ad", "application-cleanup", "dso-pipelines-pagerduty", {}],
    ["dso-infra-azure-ad", "automated-user-management", "dso-pipelines-pagerduty", {}],
    ["dso-infra-azure-ad", "send-reminders", "dso-pipelines-pagerduty", {}],
    ["dso-infra-azure-fixngo", "terragrunt-DigitalStudioDevTestEnvironments", "dso-pipelines-pagerduty", {}],
    ["dso-infra-azure-fixngo", "terragrunt-NOMSDigitalStudioProduction1", "dso-pipelines-pagerduty", {}],
    ["dso-infra-azure-fixngo", "terragrunt-NOMSDevTestEnvironments", "dso-pipelines-pagerduty", {}],
    ["dso-infra-azure-fixngo", "terragrunt-NOMSProduction1", "dso-pipelines-pagerduty", {}],
    ["dso-infra-azure-fixngo", "stale", "dso-pipelines-pagerduty", {}],
    ["dso-modernisation-platform-automation", "ssm_command_monitoring", "dso-pipelines-pagerduty", { threshold = "10" }], # pipeline sometimes fails due to API errors hence only alarm if it continually fails
    ["dso-modernisation-platform-automation", "github_workflow_monitoring", "dso-pipelines-pagerduty", { threshold = "10" }],
    ["dso-modernisation-platform-automation", "planetfm_gfsl_data_extract", "dso-pipelines-pagerduty", {}],
    ["dso-modernisation-platform-automation", "nomis_environment_start", "nomis-pagerduty", {}],
    ["dso-modernisation-platform-automation", "certificate_renewal", "dso-pipelines-pagerduty", {}],
    ["dso-modernisation-platform-automation", "azure_sas_token_refresh", "nomis-data-hub-pagerduty", {}],
    ["dso-modernisation-platform-automation", "jump_server_start", "dso-pipelines-pagerduty", {}],
    ["dso-modernisation-platform-automation", "jump_server_stop", "dso-pipelines-pagerduty", {}],
    ["dso-modernisation-platform-automation", "ncr_environment_start", "dso-pipelines-pagerduty", {}],
    ["dso-modernisation-platform-automation", "ncr_environment_stop", "dso-pipelines-pagerduty", {}],
    ["dso-modernisation-platform-automation", "ndh_offloc_cdecopy", "nomis-data-hub-pagerduty", {}],
    ["dso-modernisation-platform-automation", "ndh_offloc_cloudplatfom_copy", "dso-pipelines-pagerduty", {}],
    ["dso-modernisation-platform-automation", "nomis_environment_stop", "nomis-pagerduty", {}],
    ["dso-modernisation-platform-automation", "nomis_database_refresh", "nomis-pagerduty", {}],
    ["dso-modernisation-platform-automation", "oasys_database_refresh", "oasys-pagerduty", {}],
    ["dso-modernisation-platform-automation", "onr_environment_start", "dso-pipelines-pagerduty", {}],
    ["dso-modernisation-platform-automation", "onr_environment_stop", "dso-pipelines-pagerduty", {}],
    ["dso-modernisation-platform-automation", "security_hub_alerting", "dso-pipelines-pagerduty", {}],
    ["dso-repositories", "stale", "dso-pipelines-pagerduty", {}],
    ["dso-useful-stuff", "stale", "dso-pipelines-pagerduty", {}],
    ["dso-useful-stuff", "dangling-dns", "dso-pipelines-pagerduty", {}],
  ]

  cloudwatch_metric_alarms_github_action_failed = {
    for item in local.gha_pipeline_alarms : "${item[0]}-${item[1]}-github-action-failed" => merge(
      module.baseline_presets.cloudwatch_metric_alarms.github["failed-github-action-run"],
      item[3],
      {
        dimensions = {
          Repo         = item[0]
          WorkflowName = item[1]
        }
        alarm_actions = [item[2]]
        ok_actions    = [item[2]]
      }
    )
  }
  cloudwatch_metric_alarms_github_action_missing = {
    github-action-metrics-missing = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dso-pipelines-pagerduty"].github["github-action-metrics-missing"]
  }

  cloudwatch_metric_alarms_github_actions = merge(
    local.cloudwatch_metric_alarms_github_action_failed,
    local.cloudwatch_metric_alarms_github_action_missing
  )
}
