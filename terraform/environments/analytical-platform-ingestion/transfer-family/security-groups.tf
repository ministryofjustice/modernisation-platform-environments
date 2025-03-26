resource "aws_security_group" "transfer_server" {
  description = "Security Group for Transfer Server"
  name        = "transfer-family-server"
  vpc_id      = local.environment_configuration.isolated_vpc_id
  tags        = local.tags
}
