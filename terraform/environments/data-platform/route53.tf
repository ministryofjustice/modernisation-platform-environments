module "data_platform_development_route53" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.10.2"

  zones = {
    "development.data-platform.service.justice.gov.uk" = {
      comment = "Data Platform Development"
      tags = local.tags
    }
  }
}
