locals {

  core_network_services_domains = {
    for domain, value in var.validation : domain => value if value.account == "core-network-services"
  }
  core_vpc_domains = {
    for domain, value in var.validation : domain => value if value.account == "core-vpc"
  }
  self_domains = {
    for domain, value in var.validation : domain => value if value.account == "self"
  }

}
