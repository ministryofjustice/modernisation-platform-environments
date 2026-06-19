module "envoy_gateway" {
  source = "./modules/envoy"
}

data "aws_route53_zone" "cluster_zone" {
  name         = local.cluster_base_domain
  private_zone = false
}

module "acm" {
  source = "./modules/acm"
  cluster_name = local.cluster_name
  cluster_base_domain = local.cluster_base_domain
}


# Manual record because externalDNS doesn't know how to handle our setup
resource "aws_route53_record" "starter_pack_manual_cname" {
  zone_id = data.aws_route53_zone.cluster_zone.zone_id
  name    = "test-${local.starter_pack_httproute_hostname}"
  type    = "CNAME"
  ttl     = 60
  records = ["k8s-envoygat-envoyedg-4e232444fe-277416740.eu-west-2.elb.amazonaws.com"]
}

