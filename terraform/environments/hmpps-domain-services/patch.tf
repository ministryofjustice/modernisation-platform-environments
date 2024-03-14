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

# Test overridden baseline from same account
module "devtest" {
  count       = local.is-development == true ? 1 : 0
  source      = "../../modules/patch_manager"
  application = "hmpps-domain-services"
  environment = "devtest"
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

# Test predefined baseline from across account
module "test-predefinedbaseline" {
  count       = local.is-test == true ? 1 : 0
  source      = "../../modules/patch_manager"
  application = "hmpps-domain-services-test-predefined"
  environment = "development"
  schedule    = "cron(15 23 ? * * *)" # 11.15pm today
  target_tag = {
    "environment-name" = "hmpps-domain-services-test"
  }
}