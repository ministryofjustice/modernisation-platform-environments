# Kali Linux Instance
resource "aws_instance" "kali_linux" {
  #checkov:skip=CKV_AWS_88:instance requires internet access
  ami                         = "ami-0f398bcc12f72f967" // aws-marketplace/kali-last-snapshot-amd64-2024.2.0-804fcc46-63fc-4eb6-85a1-50e66d6c7215
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.private_subnets.0
  vpc_security_group_ids      = [aws_security_group.kali_linux_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  ebs_optimized               = true
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted   = true
    volume_size = 60
  }
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 5
    encrypted   = true
  }
  user_data = <<-EOF
              #!/bin/bash
              # Update and install dependencies
              apt-get update
              apt-get install -y wget
              

              # Download the SSM agent
              wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb

              # Install the agent
              dpkg -i amazon-ssm-agent.deb

              # Start the SSM service
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent

              # Check the status
              systemctl status amazon-ssm-agent

              # Install kali-linux-default tools
              apt-get install -y kali-linux-default
              EOF

  tags = {
    Name = "Terraform-Kali-Linux"
  }
}

# Security Group for Kali instance
# trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "kali_linux_sg" {
  name        = "allow_https"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTPS inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all traffic outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create IAM role for EC2 instances
resource "aws_iam_role" "ssm_role" {
  name = "SSMInstanceProfile"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_role.name
}

# Create the instance profile
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}