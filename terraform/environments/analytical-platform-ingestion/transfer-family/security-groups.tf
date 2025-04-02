# resource "aws_security_group" "transfer_server" {
#   description = "Security Group for Transfer Server"
#   name        = "transfer-family-server"
#   vpc_id      = data.aws_vpc.isolated.id
#   tags        = local.tags
# }


module "transfer_server_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "transfer-family-server"
  description = "Security Group for Transfer Server"
  vpc_id      = data.aws_vpc.isolated.id
}

resource "aws_security_group_rule" "this" {
  description       = "Allow inbound SFTP traffic to Transfer Server"
  type              = "ingress"
  from_port         = 2222
  to_port           = 2222
  protocol          = "tcp"
  cidr_blocks       = local.all_cidr_blocks
  security_group_id = module.transfer_server_security_group.security_group_id
}
