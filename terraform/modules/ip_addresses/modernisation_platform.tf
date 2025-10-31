locals {

  mp_ip = {
    # EC2s (azure.hmpp.root and azure.noms.root IPs)
    # IPs also defined in https://github.com/ministryofjustice/modernisation-platform/tree/main/terraform/environments/core-network-services
    ad-hmpp-dc-a   = "10.27.136.5"
    ad-hmpp-dc-b   = "10.27.137.5"
    ad-hmpp-rdlic  = "10.27.138.6"
    ad-azure-dc-a  = "10.20.104.5"
    ad-azure-dc-b  = "10.20.106.5"
    ad-azure-rdlic = "10.20.108.6"

    # Nat Endpoints Non-Live
    non-live-eu-west-2a-nat = "13.43.9.198"
    non-live-eu-west-2b-nat = "13.42.163.245"
    non-live-eu-west-2c-nat = "18.132.208.127"

    # Nat Endpoints Live
    live-eu-west-2a-nat = "13.41.38.176"
    live-eu-west-2b-nat = "3.8.81.175"
    live-eu-west-2c-nat = "3.11.197.133"
  }

  mp_ips = {
    ad_fixngo_hmpp_domain_controllers = [
      local.mp_ip["ad-hmpp-dc-a"],
      local.mp_ip["ad-hmpp-dc-b"],
    ]
    ad_fixngo_azure_domain_controllers = [
      local.mp_ip["ad-azure-dc-a"],
      local.mp_ip["ad-azure-dc-b"],
    ]
  }

  mp_cidr = merge({ for host, ip in local.mp_ip : host => "${ip}/32" }, {
    # Aggregate ranges
    development_test         = "10.26.0.0/16"
    preproduction_production = "10.27.0.0/16"

    # VPCs
    hmpps-development   = "10.26.24.0/21"
    hmpps-test          = "10.26.8.0/21"
    hmpps-preproduction = "10.27.0.0/21"
    hmpps-production    = "10.27.8.0/21"
  })

  mp_cidrs = {

    ad_fixngo_hmpp_domain_controllers = [
      local.mp_cidr["ad-hmpp-dc-a"],
      local.mp_cidr["ad-hmpp-dc-b"],
    ]
    ad_fixngo_azure_domain_controllers = [
      local.mp_cidr["ad-azure-dc-a"],
      local.mp_cidr["ad-azure-dc-b"],
    ]
    non_live_eu_west_nat = [
      local.mp_cidr["non-live-eu-west-2a-nat"],
      local.mp_cidr["non-live-eu-west-2b-nat"],
      local.mp_cidr["non-live-eu-west-2c-nat"],
    ]
    live_eu_west_nat = [
      local.mp_cidr["live-eu-west-2a-nat"],
      local.mp_cidr["live-eu-west-2b-nat"],
      local.mp_cidr["live-eu-west-2c-nat"],
    ]
  }
}
