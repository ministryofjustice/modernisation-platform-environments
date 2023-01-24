# Environment module

Module for grabbing common resources from a modernisation platform account.
Returns some useful outputs to save some typing and duplication.

## Pre-requisites

- An application configuration file accessible via http, for example [nomis.json](https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/nomis.json)
- Business-unit customer-managed keys in the `core-shared-serviced-production` account's KMS, e.g. `general-hmpps`, `ebs-hmpps`, `rds-hmpps`

## Usage

For example:

```
module "environment" {
  source = "../../modules/environment"

  environment_management = local.environment_management
  business_unit          = local.business_unit
  application_name       = local.application_name
  environment            = local.environment
  subnet_set             = local.subnet_set
}

# Access business unit CMK
module.environment.kms_keys["ebs"].arn

# Access business unit environment VPC id
module.environment.vpc.id

# Accuess private subnet ids
module.environment.subnets["private"].ids
```
