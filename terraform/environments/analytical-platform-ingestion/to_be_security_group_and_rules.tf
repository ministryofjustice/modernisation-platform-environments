
resource "aws_security_group" "to_be_transfer_server" {
  description = "To Be Security Group for Transfer Server"
  name        = "to-be-transfer-server"
  vpc_id      = module.isolated_vpc.vpc_id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = toset(flatten([
    for k, v in local.environment_configuration.transfer_server_sftp_users : [
      for cidr_blocks in v.cidr_blocks : cidr_blocks
    ]
  ]))
  # description       = each.key # meaningless if users can share IP addesses
  from_port         = 2222
  ip_protocol       = "tcp"
  to_port           = 2222
  security_group_id = aws_security_group.to_be_transfer_server.id
  cidr_ipv4         = each.value
}
