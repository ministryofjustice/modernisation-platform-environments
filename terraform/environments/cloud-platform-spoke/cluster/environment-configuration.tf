locals {
  environment_configurations = {
    development = {
      cluster_version = "1.35"
      ingress_domain  = "dev.spoke.container-platform.service.justice.gov.uk"
    }
    preproduction = {
      cluster_version = "1.35"
      ingress_domain  = "preprod.spoke.container-platform.service.justice.gov.uk"
    }
    nonlive = {
      cluster_version = "1.35"
      ingress_domain  = "nonlive.spoke.container-platform.service.justice.gov.uk"
    }
    live = {
      cluster_version = "1.35"
      ingress_domain  = "live.spoke.container-platform.service.justice.gov.uk"
    }
  }
}
