locals {
  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      vpc_cidr                   = "10.200.0.0/18"
      vpc_public_subnets         = ["10.200.0.0/27", "10.200.0.32/27", "10.200.0.64/27"]
      vpc_database_subnets       = ["10.200.0.128/27", "10.200.0.160/27", "10.200.0.192/27"]
      vpc_elasticache_subnets    = ["10.200.1.0/27", "10.200.1.32/27", "10.200.1.64/27"]
      vpc_intra_subnets          = ["10.200.1.128/27", "10.200.1.160/27", "10.200.1.192/27"]
      vpc_private_subnets        = ["10.200.32.0/21", "10.200.40.0/21", "10.200.48.0/21"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Observability Platform */
      observability_platform = "development"
    }
    test = {
      /* VPC */
      vpc_cidr                   = "10.200.64.0/18"
      vpc_public_subnets         = ["10.200.64.0/27", "10.200.64.32/27", "10.200.64.64/27"]
      vpc_database_subnets       = ["10.200.64.128/27", "10.200.64.160/27", "10.200.64.192/27"]
      vpc_elasticache_subnets    = ["10.200.65.0/27", "10.200.65.32/27", "10.200.65.64/27"]
      vpc_intra_subnets          = ["10.200.65.128/27", "10.200.65.160/27", "10.200.65.192/27"]
      vpc_private_subnets        = ["10.200.96.0/21", "10.200.104.0/21", "10.200.112.0/21"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Observability Platform */
      observability_platform = "development"
    }
    production = {
      /* VPC */
      vpc_cidr                   = "10.201.0.0/16"
      vpc_public_subnets         = ["10.201.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]
      vpc_database_subnets       = ["10.201.1.0/26", "10.0.1.64/26", "10.0.1.128/26"]
      vpc_elasticache_subnets    = ["10.201.2.0/26", "10.0.2.64/26", "10.0.2.128/26"]
      vpc_intra_subnets          = ["10.201.3.0/26", "10.0.3.64/26", "10.0.3.128/26"]
      vpc_private_subnets        = ["10.201.128.0/19", "10.0.160.0/19", "10.0.192.0/19"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Observability Platform */
      observability_platform = "production"
    }
  }
}
