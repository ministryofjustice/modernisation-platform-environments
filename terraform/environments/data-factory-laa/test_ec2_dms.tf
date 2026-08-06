# TODO: REMOVE AFTER TESTING
# EC2 instance to test db connection into cloud platform
resource "aws_security_group" "dms_test_ec2" {
  count       = local.is-test ? 1 : 0
  name        = "dms-test-ec2"
  description = "Security group for DMS test EC2 instance"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "dms_test_ec2" {
  count = local.is-test ? 1 : 0
  name  = "dms-test-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dms_test_ec2_ssm" {
  count      = local.is-test ? 1 : 0
  role       = aws_iam_role.dms_test_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "dms_test_ec2" {
  count = local.is-test ? 1 : 0
  name  = "dms-test-ec2"
  role  = aws_iam_role.dms_test_ec2[0].name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "dms_test_ec2" {
  count = local.is-test ? 1 : 0

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [aws_security_group.dms_test_ec2[0].id]

  iam_instance_profile        = aws_iam_instance_profile.dms_test_ec2[0].name
  associate_public_ip_address = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      postgresql-client \
      dnsutils \
      netcat-openbsd
  EOF

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "dms-test-ec2"
  }
}
