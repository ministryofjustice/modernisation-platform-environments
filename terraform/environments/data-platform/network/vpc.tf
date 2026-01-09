resource "aws_vpc" "main" {
  cidr_block                           = local.network_configuration.vpc.cidr_block
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = true

  tags = {
    Name = "${local.application_name}-${local.environment}"
  }
}
