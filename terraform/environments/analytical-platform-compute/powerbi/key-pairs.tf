################################################################################
# PowerBI Gateway - Key Pairs
################################################################################

# Create key pair for PowerBI Gateway instances
resource "aws_key_pair" "powerbi_gateway_keypair" {
  key_name   = "powerbi-gateway-keypair-${local.environment}"
  public_key = local.environment_configuration.powerbi_gateway.ssh_pub_key
  tags       = local.tags
}
