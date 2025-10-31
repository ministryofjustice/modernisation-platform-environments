locals {
  environment_configurations = {
    production = {
      /* VPC */
      vpc_cidr                   = "172.31.192.0/18"
      vpc_public_subnets         = ["172.31.192.0/27", "172.31.192.32/27"]                                                         # Small subnets for NAT gateways only (32 IPs each)
      vpc_intra_subnets          = ["172.31.193.0/24", "172.31.194.0/24"]                                                          # Dedicated subnets for VPC endpoints (256 IPs each)
      vpc_private_subnets        = ["172.31.200.0/21", "172.31.208.0/21", "172.31.216.0/21", "172.31.224.0/21", "172.31.232.0/21"] # 2k IPs per subnet x 5 = 10k total
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Transit Gateway */
      transit_gateway_routes = [
        "10.0.0.0/8",      # Internal 10.x.x.x
        "172.20.0.0/16",   # Cloud Platform
        "194.33.254.0/24", # SOP
        "194.33.255.0/24", # SOP
      ]
    }
  }

  environment_configuration = lookup(local.environment_configurations, local.environment, null)
}
