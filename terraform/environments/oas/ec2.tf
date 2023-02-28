locals {
  instance-userdata = <<EOF
#!/bin/bash
cd /tmp
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
EOF
}

resource "aws_instance" "oas_app_instance" {
  ami                         = local.application_data.accounts[local.environment].ec2amiid
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.id
  user_data_base64            = base64encode(local.instance-userdata)

  root_block_device {
    delete_on_termination = false
    encrypted             = true # TODO Confirm if encrypted volumes can work for OAS, as it looks like in MP they must be encrypted
    volume_size           = 40
    volume_type           = "gp2"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}-root-volume" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} Apps Server" },
  )
}

resource "aws_security_group" "ec2" {
  name        = local.application_name
  description = "OAS DB Server Security Group"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "access to the admin server"
    from_port   = 9500
    to_port     = 9500
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "Access to the admin server from workspace"
    from_port   = 9500
    to_port     = 9500
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  ingress {
    description = "Access to the managed server"
    from_port   = 9502
    to_port     = 9502
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "Access to the managed server from workspace"
    from_port   = 9502
    to_port     = 9502
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  ingress {
    description = "Access to the managed server"
    from_port   = 9514
    to_port     = 9514
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "Access to the managed server from workspace"
    from_port   = 9514
    to_port     = 9514
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  ingress {
    description = "Database connections to rds apex edw and mojfin"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "LDAP Server Connection"
    from_port   = 1389
    to_port     = 1389
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "http access from LZ to oas-mp to test connectivity"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  }

  egress {
    description = "Allow AWS SSM Session Manager"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].outbound_access_cidr]
  }
  egress {
    description = "access to the admin server"
    from_port   = 9500
    to_port     = 9500
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "Access to the admin server from workspace"
    from_port   = 9500
    to_port     = 9500
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  egress {
    description = "Access to the managed server"
    from_port   = 9502
    to_port     = 9502
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "Access to the managed server from workspace"
    from_port   = 9502
    to_port     = 9502
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  egress {
    description = "Access to the managed server"
    from_port   = 9514
    to_port     = 9514
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "Access to the managed server from workspace"
    from_port   = 9514
    to_port     = 9514
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  egress {
    description = "Database connections from rds apex edw and mojfin"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "LDAP Server Connection"
    from_port   = 1389
    to_port     = 1389
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "Outbound internet access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].outbound_access_cidr]
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_name}-ec2-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  name                = "${local.application_name}-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  assume_role_policy  = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_instance_policy" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name}-ec2-policy"
  role = aws_iam_role.ec2_instance_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
        ],
        Resource = [
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001",
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
        ],
        Resource = [
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*",
        ]
      }
    ]
  })
}

resource "aws_ebs_volume" "EC2ServerVolumeORAHOME" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].orahomesize
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].orahome_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-EC2ServerVolumeORAHOME" },
  )
}

resource "aws_volume_attachment" "oas_EC2ServerVolume01" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.EC2ServerVolumeORAHOME.id
  instance_id = aws_instance.oas_app_instance.id
}

resource "aws_route53_record" "oas-app" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.inner.zone_id
  name     = "${local.application_name}.${data.aws_route53_zone.inner.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.oas_app_instance.private_ip]
}
