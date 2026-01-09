locals {
  route53_dns_firewall_aws_managed_domain_lists = {
    AWSManagedDomainsAggregateThreatList       = "rslvr-fdl-4e96d4ce77f466b"
    AWSManagedDomainsAmazonGuardDutyThreatList = "rslvr-fdl-876a86d96f294739"
    AWSManagedDomainsBotnetCommandandControl   = "rslvr-fdl-3268f74d91fe418f"
    AWSManagedDomainsMalwareDomainList         = "rslvr-fdl-4fc4edfc63854751"
  }
}

resource "aws_route53_resolver_firewall_config" "main" {
  resource_id        = aws_vpc.main.id
  firewall_fail_open = "ENABLED"
}

resource "aws_route53_resolver_firewall_rule_group" "aws_managed_domains" {
  name = "aws-managed-domains"
}

resource "aws_route53_resolver_firewall_rule" "aws_managed_domains" {
  for_each = local.route53_dns_firewall_aws_managed_domain_lists

  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.aws_managed_domains.id

  name                    = each.key
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = each.value

  priority = format("10%d", index(keys(local.route53_dns_firewall_aws_managed_domain_lists), each.key))
}

resource "aws_route53_resolver_firewall_rule_group_association" "aws_managed_domains" {
  name                   = "aws-managed-domains"
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.aws_managed_domains.id
  priority               = 101
  vpc_id                 = aws_vpc.main.id
}
