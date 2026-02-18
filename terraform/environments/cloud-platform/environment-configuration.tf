locals {
  environment_configurations = {
    development = {
      account_subdomain_name = "development-temp.${local.base_domain}"
    }
    preproduction = {
      account_subdomain_name = "preproduction-temp.${local.base_domain}"
    }
    nonlive = {
      account_subdomain_name = "nonlive-temp.${local.base_domain}"
    }
    live = {
      account_subdomain_name = "live-temp.${local.base_domain}"
    }
  }
}
