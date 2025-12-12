locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      vpc_cidr_block = "10.0.0.0/16"
      vpc_subnets = {
        data = {
          a = {
            cidr_block = "10.0.0.0/24"
          }
          b = {
            cidr_block = "10.0.1.0/24"
          }
          c = {
            cidr_block = "10.0.2.0/24"
          }
        }
        firewall = {
          a = {
            cidr_block = "10.0.3.0/24"
          }
          b = {
            cidr_block = "10.0.4.0/24"
          }
          c = {
            cidr_block = "10.0.5.0/24"
          }
        }
        private = {
          a = {
            cidr_block = "10.0.6.0/24"
          }
          b = {
            cidr_block = "10.0.7.0/24"
          }
          c = {
            cidr_block = "10.0.8.0/24"
          }
        }
        public = {
          a = {
            cidr_block = "10.0.9.0/24"
          }
          b = {
            cidr_block = "10.0.10.0/24"
          }
          c = {
            cidr_block = "10.0.11.0/24"
          }
        }
      }
    }
    test          = {}
    preproduction = {}
    production    = {}
  }
}
