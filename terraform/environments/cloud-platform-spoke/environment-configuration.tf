locals {
  environment_configurations = {
    development = {
      account_subdomain_name = "development.${local.base_domain}"
      cluster_version        = "1.35"
      ingress_domain         = "dev.spoke.container-platform.service.justice.gov.uk"
    }
    preproduction = {
      account_subdomain_name = "preproduction.${local.base_domain}"
      cluster_version        = "1.35"
      ingress_domain         = "preprod.spoke.container-platform.service.justice.gov.uk"
    }
    nonlive = {
      account_subdomain_name = "nonlive.${local.base_domain}"
      cluster_version        = "1.35"
      ingress_domain         = "nonlive.spoke.container-platform.service.justice.gov.uk"
    }
    live = {
      account_subdomain_name = "live.${local.base_domain}"
      cluster_version        = "1.35"
      ingress_domain         = "live.spoke.container-platform.service.justice.gov.uk"
    }
  }
}
