module "development_zone" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=f56825af8cb08bec2478e2f62b678e51986c1531" # v5.0.0

  count = terraform.workspace == "data-platform-development" ? 1 : 0

  zones = {
    "development.data-platform.service.justice.gov.uk" = {}
  }
}

module "preproduction_zone" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=f56825af8cb08bec2478e2f62b678e51986c1531" # v5.0.0

  count = terraform.workspace == "data-platform-preproduction" ? 1 : 0

  zones = {
    "preproduction.data-platform.service.justice.gov.uk" = {}
  }
}

module "production_zone" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=f56825af8cb08bec2478e2f62b678e51986c1531" # v5.0.0

  count = terraform.workspace == "data-platform-production" ? 1 : 0

  zones = {
    "data-platform.service.justice.gov.uk" = {}
  }
}

module "test_zone" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=f56825af8cb08bec2478e2f62b678e51986c1531" # v5.0.0

  count = terraform.workspace == "data-platform-test" ? 1 : 0

  zones = {
    "test.data-platform.service.justice.gov.uk" = {}
  }
}
