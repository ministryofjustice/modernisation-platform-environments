resource "aws_route53_resolver_firewall_domain_list" "moj_blocklist" {
  name = "moj-blocklist"
  domains = sort(compact([
    for domain in split(",", data.aws_secretsmanager_secret_version.route53_resolver_moj_blocklist.secret_string) : trimspace(domain)
  ]))
}

resource "aws_route53_resolver_firewall_rule_group" "moj_blocklist" {
  name = "moj-blocklist"
}

resource "aws_route53_resolver_firewall_rule" "moj_blocklist" {
  name                    = "moj-blocklist"
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.moj_blocklist.id
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.moj_blocklist.id
  priority                = 100
}

resource "aws_route53_resolver_firewall_rule_group_association" "moj_blocklist" {
  name                   = "moj-blocklist"
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.moj_blocklist.id
  priority               = 102
  vpc_id                 = module.vpc.vpc_id
}
