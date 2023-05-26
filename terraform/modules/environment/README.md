# Environment module

Module for grabbing common resources from a modernisation platform environment
account. This doesn't create any resources. It does output some common data
resources and local variables which are often needed, such as:

- vpc and subnet ids
- business unit kms keys
- domain names
- route53 zones (top level and business unit specific)

## Pre-requisites

- An application configuration file accessible via http, for example [nomis.json](https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/nomis.json)
- Business-unit customer-managed keys in the `core-shared-serviced-production` account's KMS, e.g. `general-hmpps`, `ebs-hmpps`, `rds-hmpps`
- Modernisation platform provided Route53 zones (top level zones in `core-network-services` account and business unit zones in `core-vpc` account)

## Usage

For example:

```
module "environment" {
  source = "../../modules/environment"

  providers = {
    aws.modernisation-platform = aws.modernisation-platform
    aws.core-network-services  = aws.core-network-services
    aws.core-vpc               = aws.core-vpc
  }

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

# Access private subnet ids
module.environment.subnets["private"].ids

# Access application public and/or internal domain name
module.environment.domains.public.application_environment
module.environment.domains.internal.application_environment

# Access business unit specific public route53_zone id
module.environment.route53_zones[module.environment.domains.public.business_unit_environment].id
```
