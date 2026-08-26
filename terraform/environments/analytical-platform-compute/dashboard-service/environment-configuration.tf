locals {
  environment_configurations = {
    development = {
      /* Dashboard Service */
      dashboard_service_auth0_domain = "dev-analytics-moj.eu.auth0.com"
      dashboard_service_hostname     = "dashboards.development.analytical-platform.service.justice.gov.uk"
    }
    test = {
    }
    production = {
      /* Dashboard Service */
      dashboard_service_auth0_domain = "alpha-analytics-moj.eu.auth0.com"
      dashboard_service_hostname     = "dashboards.analytical-platform.service.justice.gov.uk"
    }
  }
}
