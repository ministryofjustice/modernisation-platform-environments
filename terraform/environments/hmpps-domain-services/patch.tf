module "development" {
  count               = local.is-development == true ? 1 : 0
  source              = "../../modules/patch_manager"
  application         = "hmpps-domain-services"
  environment         = "development"
  predefined_baseline = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
  operating_system    = "WINDOWS"
  schedule            = "cron(0 21 ? * TUE#2 *)" # 2nd Tues @ 9pm
  target_tag = {
    "environment-name" = "hmpps-domain-services-development"
  }
}

module "test" {
  count               = local.is-test == true ? 1 : 0
  source              = "../../modules/patch_manager"
  application         = "hmpps-domain-services"
  environment         = "test"
  predefined_baseline = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
  operating_system    = "WINDOWS"
  schedule            = "cron(0 21 ? * WED#2* *)" # 2nd Weds @ 9pm
  target_tag = {
    "environment-name" = "hmpps-domain-services-test"
  }
}

module "preproduction" {
  count               = local.is-preproduction == true ? 1 : 0
  source              = "../../modules/patch_manager"
  application         = "hmpps-domain-services"
  environment         = "preproduction"
  predefined_baseline = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
  operating_system    = "WINDOWS"
  schedule            = "cron(0 21 ? * WED#3 *)" # 3rd Weds @ 9pm
  target_tag = {
    "environment-name" = "hmpps-domain-services-preproduction"
  }
}

module "production" {
  count               = local.is-production == true ? 1 : 0
  source              = "../../modules/patch_manager"
  application         = "hmpps-domain-services"
  environment         = "production"
  predefined_baseline = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
  operating_system    = "WINDOWS"
  schedule            = "cron(0 21 ? * THU#3 *)" # 3rd Thurs @ 9pm
  target_tag = {
    "environment-name" = "hmpps-domain-services-production"
  }
}