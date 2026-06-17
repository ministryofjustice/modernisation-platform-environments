resource "aws_security_group" "transfer" {
  description = "Inbound ports for AWS Transfer VPC endpoints"
  name        = "transfer"
  vpc_id      = module.isolated_vpc.vpc_id
}

resource "aws_security_group_rule" "transfer_inbound_sftp" {
  description       = "Inbound rule for SFTP protocol on port 22"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.transfer.id
  cidr_blocks       = local.custom_idp_configuration.ingress_cidr_blocks
}

resource "aws_security_group_rule" "transfer_inbound_ftps_control" {
  description       = "Inbound rule for FTPS control channel on port 21"
  type              = "ingress"
  from_port         = 21
  to_port           = 21
  protocol          = "tcp"
  security_group_id = aws_security_group.transfer.id
  cidr_blocks       = local.custom_idp_configuration.ingress_cidr_blocks
}

resource "aws_security_group_rule" "transfer_inbound_ftps_passive" {
  description       = "Inbound rule for FTPS passive data channel ports"
  type              = "ingress"
  from_port         = 8192
  to_port           = 8200
  protocol          = "tcp"
  security_group_id = aws_security_group.transfer.id
  cidr_blocks       = local.custom_idp_configuration.ingress_cidr_blocks
}
