locals {
  vpc_flow_logs_cloudwatch_log_group_name = "/aws/vpc/flow-log"

  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      vpc_cidr                   = "10.0.0.0/16"
      vpc_private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      vpc_public_subnets         = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true

      /* Observability Platform */
      observability_platform = "development"
    }
    test = {
      /* VPC */
      vpc_cidr                   = "10.0.0.0/16"
      vpc_private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      vpc_public_subnets         = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true

      /* Observability Platform */
      observability_platform = "development"
    }
    production = {
      /* VPC */
      vpc_cidr                   = "10.0.0.0/16"
      vpc_private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      vpc_public_subnets         = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true

      /* Observability Platform */
      observability_platform = "production"
    }
  }
}
