locals {
  environment_configurations = {
    development = {
      account_subdomain_name = "development.${local.base_domain}"
    }
    preproduction = {
      account_subdomain_name = "preproduction.${local.base_domain}"
    }
    nonlive = {
      account_subdomain_name = "nonlive.${local.base_domain}"
    }
    live = {
      account_subdomain_name = "live.${local.base_domain}"
    }
  }
}
