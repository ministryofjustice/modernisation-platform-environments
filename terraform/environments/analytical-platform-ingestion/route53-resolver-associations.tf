module "connected_vpc_route53_resolver_associations" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/route53/aws//modules/resolver-rule-associations"
  version = "5.0.0"

  vpc_id = module.connected_vpc.vpc_id

  resolver_rule_associations = {
    mojo-dns-resolver-dom1-infra-int = {
      resolver_rule_id = aws_route53_resolver_rule.mojo_dns_resolver_dom1_infra_int.id
    }
  }
}
