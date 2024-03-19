module "development" {
  count       = local.is-development == true ? 1 : 0
  source      = "../../modules/patch_manager"
  application = "hmpps-domain-services"
  environment = "development"
  schedule    = "cron(15 23 ? * * *)" # 11.15pm today
  target_tag = {
    "environment-name" = "hmpps-domain-services-development"
  }
}

module "test" {
  count       = local.is-test == true ? 1 : 0
  source      = "../../modules/patch_manager"
  application = "hmpps-domain-services"
  environment = "test"
  schedule    = "cron(15 23 ? * * *)" # 11.15pm today
  target_tag = {
    "environment-name" = "hmpps-domain-services-test"
  }
}
