
# This adds a simple EC2 instance with SFTP capabilities using AWS SSM for management to be used for the purposes of testing the ftp lambdas.

resource "aws_iam_role" "ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_iam_policy" "ssm_read_password" {
  name = "AllowReadSftpTestPassword"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter"
        ],
        Resource = "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids[terraform.workspace]}:parameter/sftp_test_ec2_password"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ssm_read_password" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = aws_iam_policy.ssm_read_password.arn
}

resource "aws_security_group" "sftp_sg" {
  name_prefix = "sftp-allow"
  description = "Allow SSH/SFTP access"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] 
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] 
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "sftp_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [aws_security_group.sftp_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ftp-server"
    }
  )
}



