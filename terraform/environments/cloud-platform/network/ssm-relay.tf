###############################################################################
# SSM Relay — Private EKS API access (ADR-016 spike, #8370)
#
# Lightweight SSM Session Manager relay for accessing the private EKS API
# endpoint without a public endpoint or VPN. Development account only.
###############################################################################

# Look up the existing cluster VPC (spike uses local state, so not via module).
data "aws_vpc" "cluster" {
  filter {
    name   = "tag:Name"
    values = [local.cp_vpc_name]
  }
}

# Look up the existing private (node) subnets in that VPC.
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.cluster.id]
  }
  filter {
    name   = "tag:SubnetType"
    values = ["Private"]
  }
}

# IAM role assumed by the SSM relay EC2 instance (dev account only).
resource "aws_iam_role" "ssm_relay" {
  count = local.is-development ? 1 : 0

  name = "ssm-relay-${local.cp_vpc_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

# Grants the SSM agent core permissions to register with Systems Manager.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  count = local.is-development ? 1 : 0

  role       = aws_iam_role.ssm_relay[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile that lets the EC2 relay instance use the SSM role.
resource "aws_iam_instance_profile" "ssm_relay" {
  count = local.is-development ? 1 : 0

  name = "ssm-relay-${local.cp_vpc_name}"
  role = aws_iam_role.ssm_relay[0].name
}

# Security group for the relay: no inbound, outbound HTTPS only (SSM is outbound).
resource "aws_security_group" "ssm_relay" {
  count = local.is-development ? 1 : 0

  name_prefix = "ssm-relay-"
  description = "SSM relay for private EKS API access - outbound HTTPS only"
  vpc_id      = data.aws_vpc.cluster.id

  egress {
    description = "HTTPS to SSM endpoints and EKS API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS (UDP) so the SSM agent can resolve the SSM endpoint FQDNs.
  egress {
    description = "DNS over UDP to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS (TCP) fallback for large responses.
  egress {
    description = "DNS over TCP to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# Latest Amazon Linux 2023 AMI for the relay instance.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# The SSM relay instance (t3.micro) in a private subnet, IMDSv2 enforced.
resource "aws_instance" "ssm_relay" {
  count = local.is-development ? 1 : 0

  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.private.ids[0]
  iam_instance_profile   = aws_iam_instance_profile.ssm_relay[0].name
  vpc_security_group_ids = [aws_security_group.ssm_relay[0].id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge({
    Name = "ssm-relay-${local.cp_vpc_name}"
  }, local.tags)
}
