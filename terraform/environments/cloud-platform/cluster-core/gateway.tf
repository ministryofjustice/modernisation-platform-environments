# Envoy + LBC config
module "envoy_gateway" {
  source              = "./modules/envoy"
  alb_certificate_arn = module.acm.cluster_wildcard_certificate_arn
}

# Cluster wildcard certificate
module "acm" {
  source              = "./modules/acm"
  cluster_name        = local.cluster_name
  cluster_base_domain = local.cluster_base_domain
}

# Manual record because externalDNS doesn't know how to handle our setup
data "aws_route53_zone" "cluster_zone" {
  name         = local.cluster_base_domain
  private_zone = false
}

resource "aws_route53_record" "starter_pack_manual_cname" {
  zone_id = data.aws_route53_zone.cluster_zone.zone_id
  name    = "test1-${local.starter_pack_httproute_hostname}"
  type    = "CNAME"
  ttl     = 60
  records = ["k8s-envoygat-envoyedg-4e232444fe-277416740.eu-west-2.elb.amazonaws.com"]
}

resource "aws_route53_record" "starter_pack_manual_cname2" {
  zone_id = data.aws_route53_zone.cluster_zone.zone_id
  name    = "test2-${local.starter_pack_httproute_hostname}"
  type    = "CNAME"
  ttl     = 60
  records = ["k8s-envoygat-envoyedg-4e232444fe-277416740.eu-west-2.elb.amazonaws.com"]
}

resource "aws_route53_record" "starter_pack_manual_cname3" {
  zone_id = data.aws_route53_zone.cluster_zone.zone_id
  name    = "test0-${local.starter_pack_httproute_hostname}"
  type    = "CNAME"
  ttl     = 60
  records = ["k8s-envoygat-envoyedg-4e232444fe-277416740.eu-west-2.elb.amazonaws.com"]
}

resource "aws_route53_record" "path_routing_manual_cname" {
  zone_id = data.aws_route53_zone.cluster_zone.zone_id
  name    = format("multi-path.%s.%s", local.cluster_name, local.cluster_base_domain)
  type    = "CNAME"
  ttl     = 60
  records = ["k8s-envoygat-envoyedg-4e232444fe-277416740.eu-west-2.elb.amazonaws.com"]
}

