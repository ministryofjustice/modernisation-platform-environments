resource "aws_vpc" "main" {
  cidr_block                           = local.environment_configuration.vpc_cidr_block
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = true
  instance_tenancy                     = "default"

  tags = {
    Name = "${local.application_name}-${local.environment}"
  }
}
