# This adds an ec2 for use with testing the ftp lambda.
# SSH will need to be configured manually.

resource "aws_iam_role" "ssm_role" {
  count = local.build_ec2 ? 1 : 0

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
  count      = local.build_ec2 ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  count = local.build_ec2 ? 1 : 0
  name  = "ssm-instance-profile"
  role  = aws_iam_role.ssm_role[0].name
}

resource "aws_iam_policy" "ssm_read_password" {
  count = local.build_ec2 ? 1 : 0

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
  count      = local.build_ec2 ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = aws_iam_policy.ssm_read_password[0].arn
}

resource "aws_security_group" "sftp_sg" {
  count       = local.build_ec2 ? 1 : 0
  name_prefix = "sftp-allow"
  description = "Allow SSH/SFTP access"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "SSH outbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  egress {
    description = "SSH inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  egress {
    description = "SSM endpoint access"
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

# trivy:ignore:AVD-AWS-0131
resource "aws_instance" "sftp_server" {
  #checkov:skip=CKV_AWS_8:"EBS encryption using shared KMS is enforced by account default."
  #checkov:skip=CKV_AWS_135:"EC2 used for sftp testing only."
  count                  = local.build_ec2 ? 1 : 0
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [aws_security_group.sftp_sg[0].id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile[0].name

  metadata_options {
    http_tokens   = "required" # Force use of IMDSv2
    http_endpoint = "enabled"  # Enable IMDS access
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ftp-server"
    }
  )

  # This prevents the ec2 from being redeployed & so wiping any configurations.
  lifecycle {
    ignore_changes = all
  }
}


