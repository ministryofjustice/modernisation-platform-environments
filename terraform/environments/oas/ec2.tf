resource "aws_instance" "oas_app_instance" {
  ami                         = local.application_data.accounts[local.environment].ec2amiid
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  security_groups             = [aws_security_group.ec2.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_size           = 40
    volume_type           = "gp2"
  }

  volume_tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-root-volume" },
  )

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
    description     = "Allow AWS SSM Session Manager"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [local.application_data.accounts[local.environment].ssm_interface_endpoint_security_group]
  }
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

  egress {
    description     = "Allow AWS SSM Session Manager"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [local.application_data.accounts[local.environment].ssm_interface_endpoint_security_group]
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
}


data "aws_iam_policy_document" "ec2_instance_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  # name = "${local.application_name}-S3-${local.application_data.accounts[local.environment]}.bucketname-RW-ec2-profile"
  name = "${local.application_name}-ec2-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "${local.application_name}-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {"Service": "ec2.amazonaws.com"},
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_instance_policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name   = "${local.application_name}-ec2-policy"
  role   = aws_iam_role.ec2_instance_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "ec2:DescribeInstances",
                "ec2:CreateTags",
                "logs:DescribeLogStreams",
                "logs:PutRetentionPolicy",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": [
                "arn:aws:s3:::laa-software-library",
                "arn:aws:s3:::laa-software-library/*"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::laa-software-library/*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm-attach-policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = data.aws_iam_policy.ssm_ec2_policy.arn
}

resource "aws_ebs_volume" "EC2ServeVolume01" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].orahomesize
  type              = "gp3"
  encrypted         = false

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-EC2ServeVolume01" },
  )

  lifecycle {
    ignore_changes = [
      snapshot_id,
    ]
  }
}

resource "aws_volume_attachment" "oas_EC2ServeVolume01" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.EC2ServeVolume01.id
  instance_id = aws_instance.oas_app_instance.id
}

resource "aws_ebs_volume" "EC2ServeVolume02" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].stageesize
  type              = "gp3"
  encrypted         = false

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-EC2ServeVolume02" },
  )

  lifecycle {
    ignore_changes = [
      snapshot_id,
    ]
  }
}

resource "aws_volume_attachment" "oas_EC2ServeVolume02" {
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.EC2ServeVolume02.id
  instance_id = aws_instance.oas_app_instance.id
}

user_data = base64encode(templatefile("user_data.sh", {
  app_name = local.application_name
}))
