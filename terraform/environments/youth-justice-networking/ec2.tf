# External Security Group (YJBJuniperEXT-SG)
resource "aws_security_group" "external_sg" {
  name        = "YJBJuniperEXT-SG"
  description = "External Interface Juniper Security Group"
  vpc_id      = module.vpc.vpc_id

  # Inbound Rules
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound IPSec"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ping from all"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound IKE"
  }

  # Outbound Rule (Allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.tags, {
    Name = "YJBJuniperEXT-SG"
  })
}

# Internal Security Group (Placeholder)
resource "aws_security_group" "internal_sg" {
  name        = "YJBJuniperINT-SG"
  description = "Internal Juniper Security Group (Placeholder)"
  vpc_id      = module.vpc.vpc_id

  # No rules defined yet, will update in the future
  tags = merge(local.tags, {
    Name = "YJBJuniperINT-SG"
  })
}

# EC2 Instance (vSRX01)
resource "aws_instance" "vsrx01" {
  ami                         = "ami-0ad7c5b240d3318e2"  # Replace with correct AMI ID
  instance_type               = "c5.xlarge"
  key_name                    = "Juniper_KeyPair"       # Replace with your SSH key name
#   subnet_id                   = aws_subnet.vsrx_subnets["vSRX01 Management Range"].id

  # Attach the Management Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx01_enis["vSRX01 Management Interface"].id
    device_index         = 0  # Primary interface (eth0)
  }

  # Attach the PSK External Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx01_enis["vSRX01 PSK External Interface"].id
    device_index         = 1  # Secondary interface (eth1)
  }

  # Attach the Cert External Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx01_enis["vSRX01 Cert External Interface"].id
    device_index         = 2  # Tertiary interface (eth2)
  }

  # Attach the Internal Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx01_enis["vSRX01 Internal Interface"].id
    device_index         = 3  # Quaternary interface (eth3)
  }

  tags = merge(local.tags, {
    Name = "Juniper vSRX01"
  })
}
