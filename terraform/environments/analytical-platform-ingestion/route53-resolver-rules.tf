resource "aws_route53_resolver_rule" "mojo_dns_resolver_dom1_infra_int" {
  name                 = "mojo-dns-resolver-dom1-infra-int"
  domain_name          = "dom1.infra.int"
  rule_type            = "FORWARD"
  resolver_endpoint_id = module.connected_vpc_outbound_route53_resolver_endpoint.route53_resolver_endpoint_id

  /* MoJO DNS Resolver Service */
  target_ip {
    ip = "10.180.80.5"
  }

  /* MoJO DNS Resolver Service */
  target_ip {
    ip = "10.180.81.5"
  }

  tags = local.tags
}