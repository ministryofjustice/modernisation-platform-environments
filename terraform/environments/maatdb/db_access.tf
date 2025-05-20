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

resource "aws_instance" "oas_app_instance" {
  ami = "ami-0fc32db49bc3bfbb1"
  availability_zone = "eu-west-2a"
  instance_type     = "t3.small"
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  monitoring = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-db-access" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

