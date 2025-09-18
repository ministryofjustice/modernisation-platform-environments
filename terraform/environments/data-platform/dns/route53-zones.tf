module "development_zone" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=f56825af8cb08bec2478e2f62b678e51986c1531" # v5.0.0

  zones = {
    "${local.environment_configuration.route53_zone_name}" = {}
  }
}

module "preproduction_zone" {
  count = terraform.workspace == "data-platform-preproduction" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=f56825af8cb08bec2478e2f62b678e51986c1531" # v5.0.0

  zones = {
    "${local.environment_configuration.route53_zone_name}" = {}
  }
}

module "production_zone" {
  count = terraform.workspace == "data-platform-production" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=f56825af8cb08bec2478e2f62b678e51986c1531" # v5.0.0

  zones = {
    "${local.environment_configuration.route53_zone_name}" = {}
  }
}

module "test_zone" {
  count = terraform.workspace == "data-platform-test" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=f56825af8cb08bec2478e2f62b678e51986c1531" # v5.0.0

  zones = {
    "${local.environment_configuration.route53_zone_name}" = {}
  }
}
