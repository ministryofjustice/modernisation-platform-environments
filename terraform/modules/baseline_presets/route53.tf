# Return resolver endpoint configuration depending on what has been passed in
# via var.options.route53_resolver_rules.  For example, if you want to create 
# a resolver for both data and private subnets with a forwarded to the 
# azure-fixngo-domain, then configure like this
#
# options.route53_resolver_rules = {
#   outbound-data-and-private-subnets = ["azure-fixngo-domain"]
# }
#
# If you just want to forward on private subnets, configure like this
#
# options.route53_resolver_rules = {
#   outbound-private-subnets = ["azure-fixngo-domain"]
# }

locals {

  route53_resolver_rules_all = {
    azure-fixngo-devtest-domain = {
      domain_name = "azure.noms.root"
      target_ips = flatten([
        var.ip_addresses.mp_ips.ad_fixngo_azure_domain_controllers,
        var.ip_addresses.azure_fixngo_ips.devtest.domain_controllers,
      ])
      rule_type = "FORWARD"
    }
    azure-fixngo-production-domain = {
      domain_name = "azure.hmpp.root"
      target_ips = flatten([
        var.ip_addresses.mp_ips.ad_fixngo_hmpp_domain_controllers,
        var.ip_addresses.azure_fixngo_ips.prod.domain_controllers,
      ])
      rule_type = "FORWARD"
    }
    infra-int-domain-hmpp-forest-trust = {
      domain_name = "infra.int"
      target_ips = flatten([
        var.ip_addresses.mp_ips.ad_fixngo_hmpp_domain_controllers,
        var.ip_addresses.azure_fixngo_ips.prod.domain_controllers,
      ])
      rule_type = "FORWARD"
    }
  }

  route53_resolvers_rules_by_environment = {
    development = {
      azure-fixngo-domain = local.route53_resolver_rules_all.azure-fixngo-devtest-domain
    }
    test = {
      azure-fixngo-domain = local.route53_resolver_rules_all.azure-fixngo-devtest-domain
    }
    preproduction = {
      azure-fixngo-domain = local.route53_resolver_rules_all.azure-fixngo-production-domain
      infra-int-domain    = local.route53_resolver_rules_all.infra-int-domain-hmpp-forest-trust
    }
    production = {
      azure-fixngo-domain = local.route53_resolver_rules_all.azure-fixngo-production-domain
      infra-int-domain    = local.route53_resolver_rules_all.infra-int-domain-hmpp-forest-trust
    }
  }

  route53_resolver_rules = {
    for rule_key, rules_filter in var.options.route53_resolver_rules : rule_key => {
      for key, value in local.route53_resolvers_rules_by_environment[var.environment.environment] : key => value if contains(rules_filter, key)
    }
  }

  route53_resolver_list = flatten([
    try(length(local.route53_resolver_rules["outbound-data-and-private-subnets"]), 0) != 0 ? [{
      key = "outbound-data-and-private-subnets"
      value = {
        direction    = "OUTBOUND"
        subnet_names = ["data", "private"]
        rules        = local.route53_resolver_rules["outbound-data-and-private-subnets"]
      }
    }] : [],
    try(length(local.route53_resolver_rules["outbound-private-subnets"]), 0) != 0 ? [{
      key = "outbound-private-subnets"
      value = {
        direction    = "OUTBOUND"
        subnet_names = ["private"]
        rules        = local.route53_resolver_rules["outbound-private-subnets"]
      }
    }] : [],
  ])

  route53_resolvers = {
    for item in local.route53_resolver_list : item.key => item.value
  }
}

