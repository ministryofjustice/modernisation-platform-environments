locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      monitoring_stack_enabled = true
      monitoring_hostname      = "monitoring.development.data-platform.service.justice.gov.uk"
      grafana_namespace        = "data-platform-monitoring-development"
      grafana_chart_version    = "12.4.8"
    }
    test = {
      monitoring_stack_enabled = false
    }
    preproduction = {
      monitoring_stack_enabled = false
    }
    production = {
      monitoring_stack_enabled = true
      monitoring_hostname      = "monitoring.data-platform.service.justice.gov.uk"
      grafana_namespace        = "data-platform-monitoring-production"
      grafana_chart_version    = "12.4.8"
    }
  }
}
