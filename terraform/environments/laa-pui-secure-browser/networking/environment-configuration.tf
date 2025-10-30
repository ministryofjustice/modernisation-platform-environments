locals {
  environment_configurations = {
    production = {
      /* VPC */
      vpc_cidr                   = "172.31.192.0/18"
      vpc_public_subnets         = ["172.31.192.0/27", "172.31.192.32/27"]  # Small subnets for NAT gateways only (32 IPs each)
      vpc_intra_subnets          = ["172.31.192.64/27", "172.31.192.96/27"] # Dedicated subnets for VPC endpoints (32 IPs each)
      vpc_private_subnets        = ["172.31.200.0/21", "172.31.208.0/21", "172.31.216.0/21", "172.31.224.0/21", "172.31.232.0/21"] # 2k IPs per subnet x 5 = 10k total
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false
    }
  }

  environment_configuration = lookup(local.environment_configurations, local.environment, null)
}
