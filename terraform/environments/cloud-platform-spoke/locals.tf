#### This file can be used to store locals specific to the member account ####
locals {
  base_domain               = "container-platform.service.justice.gov.uk"
  environment_configuration = local.environment_configurations[local.environment]
  availability_zones        = slice(data.aws_availability_zones.available.names, 0, 3)
}
