#### Simple EC2 instance for testing purposes ####

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# IAM role/profile grants SSM access so the instance can be managed without SSH keys
resource "aws_iam_role" "ec2_test" {
  name = "ec2-sprinkler-test"

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

resource "aws_iam_role_policy_attachment" "ec2_test_ssm" {
  role       = aws_iam_role.ec2_test.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_test" {
  name = "ec2-sprinkler-test"
  role = aws_iam_role.ec2_test.name
}

resource "aws_security_group" "ec2_test" {
  #checkov:skip=CKV2_AWS_5:"Security group is attached to the EC2 instance below."
  name        = "ec2-sprinkler-test"
  description = "Controls access to the sprinkler test EC2 instance"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description     = "Allow HTTP from the ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.loadbalancer.security_group.id]
  }

  egress {
    description = "HTTPS outbound for SSM access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  tags = { Name = "ec2-sprinkler-test" }
}

resource "aws_instance" "test" {
  #checkov:skip=CKV2_AWS_41:"IAM role is attached via instance profile; no SSH key is used."
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [aws_security_group.ec2_test.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_test.name
  monitoring             = true
  ebs_optimized          = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # enforce IMDSv2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = { Name = "ec2-sprinkler-test" }
}
