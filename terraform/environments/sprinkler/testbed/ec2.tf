# Security group for EC2 instance

locals {

  # SSH public key for EC2 access
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPnOaomLFBo83Qnx6+zLvpXSfKdoI5gemGJP22NTUPhh mikereid"

}

resource "aws_security_group" "testbed" {
  name        = "${local.application_name}-${local.component_name}-ec2"
  description = "Security group for ${local.application_name} ${local.component_name} EC2 instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.component_name}-ec2"
    }
  )
}

# Allow SSH inbound
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.testbed.id
  description       = "Allow SSH inbound"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = data.aws_subnet.private_subnets_a.cidr_block
}

# Allow all outbound
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.testbed.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# SSH key pair
resource "aws_key_pair" "testbed" {
  key_name   = "${local.application_name}-${local.component_name}"
  public_key = local.ssh_public_key

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.component_name}"
    }
  )
}



# EC2 instance
resource "aws_instance" "testbed" {
  ami                    = "ami-0ab54db41b3bd815e"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.testbed.key_name
  subnet_id              = data.aws_subnets.shared-private.ids[0]
  vpc_security_group_ids = [aws_security_group.testbed.id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.component_name}"
    }
  )
}
