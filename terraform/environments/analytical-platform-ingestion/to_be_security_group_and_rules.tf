
resource "aws_security_group" "to_be_transfer_server" {
  description = "To Be Security Group for Transfer Server"
  name        = "to-be-transfer-server"
  vpc_id      = module.isolated_vpc.vpc_id
  tags        = local.tags
}

# locals {
#   # CIDR blocks for users and users-with-egress
#   cidr_blocks_distinct = setunion(
#     flatten([for k, v in local.environment_configuration.transfer_server_sftp_users : v.cidr_blocks]),
#     flatten([for k, v in local.environment_configuration.transfer_server_sftp_users_with_egress : v.cidr_blocks])
#   )
# }

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = setunion(
    flatten([for k, v in local.environment_configuration.transfer_server_sftp_users : v.cidr_blocks]),
    flatten([for k, v in local.environment_configuration.transfer_server_sftp_users_with_egress : v.cidr_blocks])
  )
  from_port         = 2222
  ip_protocol       = "tcp"
  to_port           = 2222
  security_group_id = aws_security_group.to_be_transfer_server.id
  cidr_ipv4         = each.value
}
