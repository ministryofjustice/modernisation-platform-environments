locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      isolated_vpc_public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      isolated_vpc_private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    }
    production = {
      /* VPC */
      isolated_vpc_public_subnets   = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      isolated_vpc_private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      connected_vpc_cidr            = "10.27.128.0/23"
      connected_vpc_private_subnets = ["10.27.128.0/26", "10.27.128.64/26", "10.27.128.128/26"]
      tariff_cidr                   = "10.27.80.0/21"
    }
  }
}
