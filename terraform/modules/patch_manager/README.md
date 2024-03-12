# AWS Systems Manager Patch Manager Module

- Use this module to set up a patch schedule for instances. 
- Register instances to patch by giving the `target_tag` map the tag name and value of the instance that requires patching.
- Successful patches will be picked up from the development environment and referenced by the other environments

```hcl
# Development environment will generate a list of patches
module "development" {
  source                  = "./modules/"
  application             = "hmpps-domain-services"
  environment             = "development"
  # Second Tuesday of the month at 9pm UTC
  schedule                = "cron(0 21 ? * TUE#2 *)"
  target_tag              =  {
    "environment-name" = "hmpps-domain-services-development"
  }
 }

# Other environments will reference the list of patches from development
module "test" {
  source                  = "./modules/"
  application             = "hmpps-domain-services"
  environment             = "test"
  schedule                = "cron(0 21 ? * WED#2 *)"
  target_tag              =  {
    "environment-name" = "hmpps-domain-services-test"
  }
 }
```

