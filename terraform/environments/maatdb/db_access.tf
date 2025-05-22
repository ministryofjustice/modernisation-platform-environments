locals {
  public_key_data = jsondecode(file("./files/bastion_linux.json"))
}

module "bastion_linux" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=v4.4.2"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }
  # s3 - used for logs and user ssh public keys
  bucket_name = "bastion-${local.application_name}-${local.environment}"
  # public keys
  public_key_data = local.public_key_data.keys[local.environment]
  # logs
  log_auto_clean       = "Enabled"
  log_standard_ia_days = 30  # days before moving to IA storage
  log_glacier_days     = 60  # days before moving to Glacier
  log_expiry_days      = 180 # days before log expiration
  # bastion
  allow_ssh_commands = false
  app_name           = var.networking[0].application
  business_unit      = local.vpc_name
  subnet_set         = local.subnet_set
  environment        = local.environment
  region             = "eu-west-2"

  # Tags
  tags_common = local.tags
  tags_prefix = terraform.workspace
}


# ec2 to access the RDS

resource "aws_instance" "db_access_instance" {
  ami = "ami-0fc32db49bc3bfbb1"
  availability_zone = "eu-west-2a"
  instance_type     = "t3.small"
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.ssm_ec2_profile.name
  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    delete_on_termination = true
  }
  ebs_block_device {
    device_name           = "/dev/sdf" 
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-db-access" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}


# IAM Role for SSM
resource "aws_iam_role" "ssm_ec2_role" {
  name = "ec2-ssm-role"

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

# Attach AmazonSSMManagedInstanceCore policy
resource "aws_iam_role_policy_attachment" "ssm_ec2_attach" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ssm_ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ssm_ec2_role.name
}


resource "aws_security_group" "ec2" {
  name        = local.application_name
  description = "EC2 Security Group"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "Oracle DB Access"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  egress {
    description = "Oracle DB Access"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  egress {
    description = "SSM Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


