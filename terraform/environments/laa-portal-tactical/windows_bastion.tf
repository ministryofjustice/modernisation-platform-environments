resource "aws_instance" "windows_bastion" {
  ami                         = "ami-0ef410e81da91ec11"
  availability_zone           = "eu-west-2a"
  instance_type               = "t2.large"
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  monitoring                  = true
  subnet_id                   = module.vpc.public_subnets.0
  iam_instance_profile        = aws_iam_instance_profile.portal.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.portal15_ssh.key_name

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} Windows Bastion" }
  )
}

resource "aws_key_pair" "portal15_ssh" {
  key_name   = "portal1.5-ssh-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDpAb+2L7URPwzVqFjmRq3daVTsjX2uT2UKWq8CL9dMdSRHMclgBvanEHp7QyogC9nlMjnTnoPTY2jDuQL3vjTB7i7ToRw+Hmq5QHPbNQ/+aoaNYQOIFQv6svAr1vqzD7F0N7vj19rQ+cb5tSjCobjmDE0aGScPCDEhfhoHgFVtaELtnDvxTKacS8rZbrGwISi9LYJHM1ldNFTPU3ib74cDYHO03tL1S3ric70SrN4yR3ly7caKPEL+C9ZNDjVGUs7sCgIg1+MI7mOuK1IcO9rOkItc21Qohn0MaOPbi5NoI+rkG49ueDSRrEA1gMXjBWjp5IfOy3EluqJZQNmmD0T3AVRx6fwrp9GeeHcQKdcU1ONgaUvnukgO76H/jZWgWYRUlhVIs1QhgmIenFdyKOrXXjrtDJqQutZzjO+NQTOe12AFT2Jv8fu1m/iDyQIx/NXFpiBko6tgw5NOk6l3H9j0HgVbPHP+st6ogC/dPmWDPkeUyt8Bj6fphCWmGhvm7/c= vincent.cheung@MJ004609"
}

resource "aws_security_group" "bastion" {
  name        = "windows-bastion-sg"
  description = "Windows Bastion Security Group"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "windows_bastion_local_vpc" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "-1"
}

# resource "aws_vpc_security_group_ingress_rule" "bastion_rdp_workspace" {
#   security_group_id = aws_security_group.bastion.id
#   description       = "Bastion RDP Inbound from WorkSpaces"
#   cidr_ipv4         = local.nonprod_workspaces_cidr
#   from_port         = 3389
#   ip_protocol       = "tcp"
#   to_port           = 3389
# }
