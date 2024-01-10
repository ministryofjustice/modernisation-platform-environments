data "aws_ami" "windows_server_2022" {
  most_recent = local.environment_configuration.powerbi_gateway_ec2.most_recent
  owners      = [local.environment_configuration.powerbi_gateway_ec2.owner_account]

  filter {
    name   = "name"
    values = local.environment_configuration.powerbi_gateway_ec2.name
  }
  filter {
    name   = "virtualization-type"
    values = [local.environment_configuration.powerbi_gateway_ec2.virtualization_type]
  }
}

data "aws_iam_policy_document" "powerbi_gateway_data_access" {
  statement {
    sid = "local.environment_configuration.powerbi_gateway_ec2.instance_name"

    actions = [
      "sts:AssumeRole",
    ]
    resources = formatlist("arn:aws:iam::%s:root", local.environment_configuration.powerbi_target_accounts)
  }
}

resource "aws_iam_policy" "powerbi_gateway_data_access" {
  name   = local.environment_configuration.powerbi_gateway_ec2.instance_name
  path   = "/"
  policy = data.aws_iam_policy_document.powerbi_gateway_data_access.json
}


resource "aws_key_pair" "powerbi_gateway_keypair" {
  key_name   = local.environment_configuration.powerbi_gateway_ec2.instance_name
  public_key = local.environment_configuration.powerbi_gateway_ec2.ssh_pub_key
}

module "powerbi_gateway" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "v5.6.0"

  name                        = local.environment_configuration.powerbi_gateway_ec2.instance_name
  ami                         = data.aws_ami.windows_server_2022.id
  instance_type               = local.environment_configuration.powerbi_gateway_ec2.instance_type
  key_name                    = aws_key_pair.powerbi_gateway_keypair.key_name
  monitoring                  = true
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for PowerBI Gateway Instance"
  ignore_ami_changes          = true
  enable_volume_tags          = true
  associate_public_ip_address = false
  iam_role_policies = {
    SSMCore            = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    PowerBI_DataAccess = aws_iam_policy.powerbi_gateway_data_access.arn
  }
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 100
      tags = merge({
        Name = "${local.environment_configuration.powerbi_gateway_ec2.instance_name}-root-volume"
      }, local.tags)
    },
  ]

  ebs_block_device = [
    {
      volume_type = "gp3"
      volume_size = 300
      encrypted   = true
      tags = merge({
        Name = "${local.environment_configuration.powerbi_gateway_ec2.instance_name}-data-volume"
      }, local.tags)
    }
  ]
  vpc_security_group_ids = [aws_security_group.powerbi_gateway.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "powerbi_gateway" {
  name        = local.environment_configuration.powerbi_gateway_ec2.instance_name
  description = local.environment_configuration.powerbi_gateway_ec2.instance_name
  vpc_id      = data.aws_vpc.shared.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.environment_configuration.vpc_cidr]
  }

  tags = local.tags
}