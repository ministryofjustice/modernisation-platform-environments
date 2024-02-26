# AWS Systems Manager Patch Manager Module

Use this module to set up a patch schedule for instances.  Instances are registered to patch windows via their `environment-name` tag hence this needs to align with the `application` and `environment` values given to the module.
```hcl
# Create a patch schedule using a list of approved patches
module "development" {
  source                  = "./modules/"
  application             = "hmpps-domain-services"
  environment             = "development"
  # Second Tuesday of the month at 9pm UTC
  schedule                = "cron(0 21 ? * TUE#2 *)"
  approved_patches        = var.approved_patches
}

variable "approved_patches" {
  type = list(string)
  default = ["KB5034682",
             "KB5034272"]
}
```
```hcl
# Create a patch schedule using AWS predefined patches
module "development" {
  source                  = "./modules/"
  application             = "hmpps-domain-services"
  environment             = "development"
  # Second Tuesday of the month at 9pm UTC
  schedule                = "cron(0 21 ? * TUE#2 *)"
  use_predefined_baseline = true
  predefined_baseline     = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
}
```
