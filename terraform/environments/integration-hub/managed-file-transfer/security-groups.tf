resource "aws_security_group" "transfer" {
  description = "Inbound ports for AWS Transfer VPC endpoints"
  name        = "transfer"
  vpc_id      = module.isolated_vpc.vpc_id
}

/*
resource "aws_security_group_rule" "transfer_inbound_sftp" {
  description       = "Inbound rule for SFTP protocol on port 22"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.transfer.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "transfer_inbound_ftps_control" {
  description       = "Inbound rule for FTPS protocol on port 21"
  type              = "ingress"
  from_port         = 21
  to_port           = 21
  protocol          = "tcp"
  security_group_id = aws_security_group.transfer.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "transfer_inbound_ftps_data" {
  description       = "Inbound rule for FTPS protocol on port 8192-8200"
  type              = "ingress"
  from_port         = 8192
  to_port           = 8200
  protocol          = "tcp"
  security_group_id = aws_security_group.transfer.id
  cidr_blocks       = ["0.0.0.0/0"]
}
*/