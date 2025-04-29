################################################################################
# PowerBI Gateway - Security Groups
################################################################################

# Security group for PowerBI Gateway
module "powerbi_gateway_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.environment}-powerbi-gateway-sg"
  description = "PowerBI Gateway security group"
  vpc_id      = data.aws_vpc.shared.id

  # Allow inbound HTTPS traffic from the VPC CIDR
  ingress_cidr_blocks = [data.aws_vpc.shared.cidr_block]
  ingress_rules       = ["https-443-tcp", "all-icmp"]

  # Allow all outbound traffic
  egress_rules = ["all-all"]

  tags = merge(local.tags, {
    Name      = "${local.environment}-powerbi-gateway-sg"
    Component = "powerbi-gateway"
  })
}
