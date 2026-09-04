# MP DNS Certificates Module v1.0.0 - https://github.com/ministryofjustice/modernisation-platform-terraform-dns-certificates
module "visualiser_cert" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-dns-certificates?ref=94e7ba452b40bbc5af65338dc63b6b1349e0d890"

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  application_name          = local.application_name
  subject_alternative_names = []
  is-production             = local.is-production
  production_service_fqdn   = local.is-production ? local.application_data.accounts[local.environment].api_domain : ""
  zone_name_core_vpc_public = data.aws_route53_zone.external.name
  tags                      = local.tags
}

# API DNS record > API ALB
resource "aws_route53_record" "api" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = local.application_data.accounts[local.environment].api_domain
  type     = "A"

  alias {
    name                   = module.lb_api.load_balancer.dns_name
    zone_id                = module.lb_api.load_balancer.zone_id
    evaluate_target_health = true
  }
}

# Visualiser DNS record > CloudFront distribution
resource "aws_route53_record" "visualiser" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = local.application_data.accounts[local.environment].visualiser_domain
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.visualiser.domain_name
    zone_id                = aws_cloudfront_distribution.visualiser.hosted_zone_id
    evaluate_target_health = true
  }
}
