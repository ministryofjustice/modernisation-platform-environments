locals {
  environment_configurations = {
    cloud-platform-development = {
      account_subdomain_name = "development.${local.base_domain}"
    }
    cloud-platform-preproduction = {
      account_subdomain_name = "preproduction.${local.base_domain}"
    }
    cloud-platform-live = {
      account_subdomain_name = "live.${local.base_domain}"
    }
    container-platform-octo-nonlive = {
      account_subdomain_name = "octo-nonlive.${local.base_domain}"
    }
    container-platform-octo-live = {
      account_subdomain_name = "octo-live.${local.base_domain}"
    }
    container-platform-laa-nonlive = {
      account_subdomain_name = "laa-nonlive.${local.base_domain}"
    }
    container-platform-laa-live = {
      account_subdomain_name = "laa-live.${local.base_domain}"
    }
    container-platform-hmpps-nonlive = {
      account_subdomain_name = "hmpps-nonlive.${local.base_domain}"
    }
    container-platform-hmpps-live = {
      account_subdomain_name = "hmpps-live.${local.base_domain}"
    }
  }
}
