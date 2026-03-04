module "cert_module" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-dns-certificates?ref=v1.0.0"
  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }
  application_name                          = local.application_name
  subject_alternative_names                 = ["*.webapp"]
  is-production                             = local.is-production
  production_service_fqdn                   = ""
  zone_name_core_vpc_public                 = data.aws_route53_zone.external.name
  tags                                      = local.tags
}