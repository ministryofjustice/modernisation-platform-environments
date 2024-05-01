locals {
  vpc_flow_logs_cloudwatch_log_group_name = "/aws/vpc/flow-log"
  vpc_flow_log_max_aggregation_interval   = 60

  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      vpc_cidr                   = "10.0.0.0/16"
      vpc_database_subnets       = ["10.0.1.0/26", "10.0.1.64/26", "10.0.1.128/26"]    # 10.0.1.0/24
      vpc_elasticache_subnets    = ["10.0.2.0/26", "10.0.2.64/26", "10.0.2.128/26"]    # 10.0.2.0/24
      vpc_intra_subnets          = ["10.0.3.0/26", "10.0.3.64/26", "10.0.3.128/26"]    # 10.0.3.0/24
      vpc_private_subnets        = ["10.0.128.0/19", "10.0.160.0/19", "10.0.160.0/19"] # 10.0.128.0/17
      vpc_public_subnets         = ["10.0.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]    # 10.0.0.0/24
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Observability Platform */
      observability_platform = "development"
    }
    test = {
      /* VPC */
      vpc_cidr                   = "10.0.0.0/16"
      vpc_database_subnets       = ["10.0.1.0/26", "10.0.1.64/26", "10.0.1.128/26"]    # 10.0.1.0/24
      vpc_elasticache_subnets    = ["10.0.2.0/26", "10.0.2.64/26", "10.0.2.128/26"]    # 10.0.2.0/24
      vpc_intra_subnets          = ["10.0.3.0/26", "10.0.3.64/26", "10.0.3.128/26"]    # 10.0.3.0/24
      vpc_private_subnets        = ["10.0.128.0/19", "10.0.160.0/19", "10.0.160.0/19"] # 10.0.128.0/17
      vpc_public_subnets         = ["10.0.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]    # 10.0.0.0/24
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Observability Platform */
      observability_platform = "development"
    }
    production = {
      /* VPC */
      vpc_cidr                   = "10.0.0.0/16"
      vpc_database_subnets       = ["10.0.1.0/26", "10.0.1.64/26", "10.0.1.128/26"]    # 10.0.1.0/24
      vpc_elasticache_subnets    = ["10.0.2.0/26", "10.0.2.64/26", "10.0.2.128/26"]    # 10.0.2.0/24
      vpc_intra_subnets          = ["10.0.3.0/26", "10.0.3.64/26", "10.0.3.128/26"]    # 10.0.3.0/24
      vpc_private_subnets        = ["10.0.128.0/19", "10.0.160.0/19", "10.0.160.0/19"] # 10.0.128.0/17
      vpc_public_subnets         = ["10.0.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]    # 10.0.0.0/24
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Observability Platform */
      observability_platform = "production"
    }
  }
}
