locals {
  /* Configurations */
  environment_configuration = local.environment_configurations[local.environment]
  network_configuration     = yamldecode(file("${path.module}/configuration/network.yml"))["environment"][local.environment]

  /* Subnets
    - Build a map of subnets from the network configuration excluding unallocated AZs
      which results in:
        {
          "data-aza" = {
            "az"         = "a"
            "cidr_block" = "10.199.128.0/25"
            "type"       = "data"
          }
        }
  */
  subnets = merge([
    for subnet_type, azs in local.network_configuration.vpc.subnets : {
      for az, cidr in azs :
      "${subnet_type}-${az}" => {
        cidr_block = cidr
        type       = subnet_type
        az         = trimprefix(az, "az")
      }
    }
  ]...)

  /* Firewall rules */
  network_firewall_rules = {
    fqdn = yamldecode(file("${path.module}/configuration/network-firewall/rules/fqdn-rules.yml"))
    ip   = yamldecode(file("${path.module}/configuration/network-firewall/rules/ip-rules.yml"))
  }
}
