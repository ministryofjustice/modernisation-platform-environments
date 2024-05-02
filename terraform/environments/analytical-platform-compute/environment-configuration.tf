locals {
  vpc_flow_logs_cloudwatch_log_group_name = "/aws/vpc/flow-log"
  vpc_flow_log_max_aggregation_interval   = 60

  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      vpc_cidr                   = "10.200.0.0/17"
      vpc_public_subnets         = ["10.200.0.0/26", "10.200.0.64/26", "10.200.0.128/26"] # 10.200.0.0/24
      vpc_database_subnets       = ["10.200.1.0/26", "10.200.1.64/26", "10.200.1.128/26"] # 10.200.1.0/24
      vpc_elasticache_subnets    = ["10.200.2.0/26", "10.200.2.64/26", "10.200.2.128/26"] # 10.200.2.0/24
      vpc_intra_subnets          = ["10.200.3.0/26", "10.200.3.64/26", "10.200.3.128/26"] # 10.200.3.0/24
      vpc_private_subnets        = ["10.200.64.0/20", "10.200.80.0/20", "10.200.96.0/20"] # 10.200.128.0/18
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Observability Platform */
      observability_platform = "development"
    }
    test = {
      /* VPC */
      vpc_cidr                   = "10.200.128.0/17"
      vpc_public_subnets         = ["10.200.128.0/26", "10.200.128.64/26", "10.200.128.128/26"] # 10.200.128.0/24
      vpc_database_subnets       = ["10.200.129.0/26", "10.200.129.64/26", "10.200.129.128/26"] # 10.200.129.0/24
      vpc_elasticache_subnets    = ["10.200.130.0/26", "10.200.130.64/26", "10.200.130.128/26"] # 10.200.130.0/24
      vpc_intra_subnets          = ["10.200.131.0/26", "10.200.131.64/26", "10.200.131.128/26"] # 10.200.131.0/24
      vpc_private_subnets        = ["10.200.192.0/20", "10.200.208.0/20", "10.200.224.0/20"]    # 10.200.192.0/18
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Observability Platform */
      observability_platform = "development"
    }
    production = {
      /* VPC */
      vpc_cidr                   = "10.201.0.0/16"
      vpc_public_subnets         = ["10.201.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]    # 10.0.0.0/24
      vpc_database_subnets       = ["10.201.1.0/26", "10.0.1.64/26", "10.0.1.128/26"]    # 10.0.1.0/24
      vpc_elasticache_subnets    = ["10.201.2.0/26", "10.0.2.64/26", "10.0.2.128/26"]    # 10.0.2.0/24
      vpc_intra_subnets          = ["10.201.3.0/26", "10.0.3.64/26", "10.0.3.128/26"]    # 10.0.3.0/24
      vpc_private_subnets        = ["10.201.128.0/19", "10.0.160.0/19", "10.0.192.0/19"] # 10.0.128.0/17
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Observability Platform */
      observability_platform = "production"
    }
  }
}
