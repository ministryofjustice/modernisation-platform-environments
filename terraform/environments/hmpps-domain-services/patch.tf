# Create a patch schedule using AWS predefined patches
module "development" {
  source                  = "../../modules/patch_manager"
  application             = "hmpps-domain-services"
  environment             = "development"
  # Second Tuesday of the month at 9pm UTC
  schedule                = "cron(0 21 ? * TUE#2 *)"
  use_predefined_baseline = true
  predefined_baseline     = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
}