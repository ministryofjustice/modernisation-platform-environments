# External Security Group (YJBJuniperEXT-SG)
resource "aws_security_group" "external_sg" {
  name        = "YJBJuniperEXT-SG"
  description = "External Interface Juniper Security Group"
  vpc_id      = module.vpc.vpc_id

  # Inbound Rules
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound IKE"
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
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound IPSec"
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

  # Inbound Rules
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.22.0/24"]
    description = "Branch Juniper PSK Interface 1 access to KMS Server on port 443"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.22.0/24"]
    description = "Branch Juniper PSK Interface 1 access to KMS Server on port 80"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.100.50.0/24"]
    description = "Management to Juniper SSH Interfaces"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.100.50.0/24"]
    description = "Management to Juniper HTTPS interfaces"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.24.0/24"]
    description = "Branch Juniper PSK Interface 2 access to KMS Server on port 443"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.24.0/24"]
    description = "Branch Juniper PSK Interface 2 access to KMS Server on port 80"
  }

  ingress {
    from_port   = 8080
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["10.26.144.0/24"]
    description = "Sandpit YJSM to CUG Junipers port 8080 - 8090"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.26.144.0/24"]
    description = "Sandpit YJSM to CUG Junipers port 80"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.26.144.0/24"]
    description = "Sandpit YJSM to CUG Junipers port 443"
  }

  ingress {
    from_port   = 8080
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["10.27.144.0/24"]
    description = "Pre-Prod YJSM to CUG Junipers port 8080 - 8090"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.27.144.0/24"]
    description = "Pre-Prod YJSM to CUG Junipers port 80"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.27.144.0/24"]
    description = "Pre-Prod YJSM to CUG Junipers port 443"
  }

  ingress {
    from_port   = 9103
    to_port     = 9103
    protocol    = "tcp"
    cidr_blocks = ["10.27.144.0/24"]
    description = "Pre-Prod YJSM to CUG Junipers port 9103"
  }

  ingress {
    from_port   = 8080
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["10.27.152.0/24"]
    description = "Prod YJSM to CUG Junipers port 8080 - 8090"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.27.152.0/24"]
    description = "Prod YJSM to CUG Junipers port 80"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.27.152.0/24"]
    description = "Prod YJSM to CUG Junipers port 443"
  }

  ingress {
    from_port   = 9103
    to_port     = 9103
    protocol    = "tcp"
    cidr_blocks = ["10.27.152.0/24"]
    description = "Prod YJSM to CUG Junipers port 9103"
  }

  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = ["10.100.120.0/24"]
    description = "Internal Juniper vSRX01 access to syslog server"
  }

  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = ["10.0.22.0/24"]
    description = "Branch Junipers AWS1 access to syslog server"
  }

  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = ["10.0.24.0/24"]
    description = "Branch Junipers AWS2 access to syslog server"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.100.120.0/24"]
    description = "Internal Juniper vSRX01 access to KMS website on port 80"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.100.120.0/24"]
    description = "Internal Juniper vSRX01 access to KMS website on port 443"
  }

  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = ["10.100.220.0/24"]
    description = "Internal Juniper vSRX02 access to syslog server"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.100.220.0/24"]
    description = "Internal Juniper vSRX02 access to KMS website on port 80"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.100.50.0/24"]
    description = "Internal Juniper access to KMS website on port 80"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.100.220.0/24"]
    description = "Internal Juniper vSRX02 access to KMS website on port 443"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.100.50.0/24"]
    description = "Internal Juniper access to KMS website on port 80"
  }

  tags = merge(local.tags, {
    Name = "YJBJuniperINT-SG"
  })
}

# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.yjb_juniper_ec2_role.name
}

# Create instance profile for EC2 instances 
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "YJBJuniperSSMInstanceProfile"
  role = aws_iam_role.yjb_juniper_ec2_role.name
}

# EC2 Instance (vSRX01)
resource "aws_instance" "vsrx01" {
  ami                  = "ami-0ad7c5b240d3318e2" # Juniper VSRX marketplace AMI
  instance_type        = "c5.xlarge"
  key_name             = "Juniper_KeyPair" # Replace with your SSH key name
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  # Attach the Management Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx01_enis["vSRX01 Management Interface"].id
    device_index         = 0 # Primary interface (eth0)
  }

  # Attach the PSK External Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx01_enis["vSRX01 PSK External Interface"].id
    device_index         = 1 # Secondary interface (eth1)
  }

  # Attach the Internal Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx01_enis["vSRX01 Internal Interface"].id
    device_index         = 2 # Quaternary interface (eth2)
  }

  # Attach the Cert External Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx01_enis["vSRX01 Cert External Interface"].id
    device_index         = 3 # Tertiary interface (eth3)
  }

  tags = merge(local.tags, {
    Name = "Juniper vSRX01"
  })
}

# EC2 Instance (vSRX02)
resource "aws_instance" "vsrx02" {
  ami                  = "ami-0ad7c5b240d3318e2" # Juniper VSRX marketplace AMI
  instance_type        = "c5.xlarge"
  key_name             = "Juniper_KeyPair" # Replace with your SSH key name
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  # Attach the Management Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx02_enis["vSRX02 Management Interface"].id
    device_index         = 0 # Primary interface (eth0)
  }

  # Attach the PSK External Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx02_enis["vSRX02 PSK External Interface"].id
    device_index         = 1 # Secondary interface (eth1)
  }

  # Attach the Internal Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx02_enis["vSRX02 Internal Interface"].id
    device_index         = 2 # Quaternary interface (eth2)
  }

  # Attach the Cert External Interface
  network_interface {
    network_interface_id = aws_network_interface.vsrx02_enis["vSRX02 Cert External Interface"].id
    device_index         = 3 # Tertiary interface (eth3)
  }

  tags = merge(local.tags, {
    Name = "Juniper vSRX02"
  })
}

#  EC2 Instance (Juniper Key Management Server)
resource "aws_instance" "juniper_kms" {
  ami                    = "ami-079423e9cb7067f4b" # AMI snapshot migrated from the old account
  instance_type          = "t3.medium"
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  subnet_id              = aws_subnet.vsrx_subnets["Juniper Management & KMS"].id
  private_ip             = "10.100.50.100"
  vpc_security_group_ids = [aws_security_group.internal_sg.id]

  tags = merge(local.tags, {
    Name          = "Juniper Key Management Server"
    "Patch Group" = "Windows"
  })
}

# EC2 Instance (Juniper Management Server)
resource "aws_instance" "juniper_management" {
  ami                  = data.aws_ami.windows_server.id # Use data source instead of hardcoded AMI
  instance_type        = "t3.large"
  key_name             = "Juniper_KeyPair"
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  subnet_id            = aws_subnet.vsrx_subnets["Juniper Management & KMS"].id
  private_ip           = "10.100.50.150"
  root_block_device {
    volume_size = 70    # Define the root volume size in GB
    volume_type = "gp3" # Optional: Specify the volume type (e.g., gp3, gp2, io1)
  }
  vpc_security_group_ids = [aws_security_group.internal_sg.id]

  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(local.tags, {
    Name          = "Juniper Management Server"
    "Patch Group" = "Windows"
  })
}

resource "aws_ebs_volume" "data_volume" {
  availability_zone = aws_instance.juniper_management.availability_zone
  size              = 80
  type              = "gp3"
  encrypted         = true
  tags              = local.tags
}

resource "aws_volume_attachment" "data_attach" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.data_volume.id
  instance_id  = aws_instance.juniper_management.id
  force_detach = true
}

# Add data sources for AMIs
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["CIS Amazon Linux 2 Kernel 5.10 Benchmark*Level 1*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "windows_server" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["CIS Microsoft Windows Server 2025*Level 1*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}