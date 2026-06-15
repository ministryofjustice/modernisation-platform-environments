locals {
  environment_configurations = {
    development = {
      /* Data Platform App */
      data_platform_app_hostname     = "development.data-platform.service.justice.gov.uk"
    }
    production = {
      /* Data Platform App */
      data_platform_app_hostname     = "data-platform.service.justice.gov.uk"
    }
  }
}
