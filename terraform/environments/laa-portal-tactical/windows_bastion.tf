resource "aws_instance" "windows_bastion" {
  ami                         = "ami-070c9a4ee0e5d83d5"
  availability_zone           = "eu-west-2a"
  instance_type               = "t2.large"
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  monitoring                  = true
  subnet_id                   = module.vpc.public_subnets.0
  iam_instance_profile        = aws_iam_instance_profile.portal.id
  associate_public_ip_address = true

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} Windows Bastion" }
  )
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
