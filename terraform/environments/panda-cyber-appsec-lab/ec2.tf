# Kali Linux Instance
resource "aws_instance" "kali_linux" {
  ami                  = "ami-07c1b39b7b3d2525d"
  instance_type        = "t2.micro"
  subnet_id            = module.vpc.private_subnets.0
  security_groups      = ["aws_security_group.allow_https"]
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  ebs_optimized        = true
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted = true
  }
  ebs_block_device {
    device_name = "/dev/xvda"
    encrypted   = true
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update && sudo apt -y install software-properties-common
              sudo wget -q -O - https://archive.kali.org/archive-key.asc | sudo apt-key add -
              sudo echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" | sudo tee /etc/apt/sources.list.d/kali.list
              sudo apt update && sudo apt -y install kali-linux-default
              EOF

  tags = {
    Name = "Terraform-Kali-Linux"
  }
}

# Security Group for Kali instance
resource "aws_security_group" "allow_https" {
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
    description = "Allow all tarffic outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
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