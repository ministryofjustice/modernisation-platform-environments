module "zone" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=f56825af8cb08bec2478e2f62b678e51986c1531" # v5.0.0

  zones = {
    (local.environment_configuration.route53_zone_name) = {}
  }
}
