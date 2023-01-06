resource "aws_instance" "oas_app_instance" {
  ami           = local.application_data.accounts[local.environment].ec2amiid
  instance_type = local.application_data.accounts[local.environment].ec2instancetype
  security_groups = [aws_security_group.ec2.id]
  #iam_instance_profile = [appec2instanceprofile]
  iam_instance_profile = [aws_iam_instance_profile.ec2_instance_profile.name]

  tags = {
    Name = ""
  }
}

resource "aws_security_group" "ec2" {
  name        = local.application_name
  description = "OAS DB Server Security Group"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
      description     = "Access from Bastion via SSH"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-BastionSSHCIDR
    }
  ingress {
      description     = "Access from env-ManagementCIDR via SSH"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-ManagementCIDR
    }
  ingress {
      description     = "Access from env-VpcCidr via SSH"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!!ImportValue env-VpcCidr
    }
  ingress {
      description     = "access to the admin server"
      from_port       = 9500
      to_port         = 9500
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
    }
  ingress {
      description     = "Access to the admin server from workspace"
      from_port       = 9500
      to_port         = 9500
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-ManagementCIDR
    }
  ingress {
      description     = "Access to the managed server"
      from_port       = 9502
      to_port         = 9502
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
    }
  ingress {
      description     = "Access to the managed server from workspace"
      from_port       = 9502
      to_port         = 9502
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-ManagementCIDR
    }
  ingress {
      description     = "Access to the managed server"
      from_port       = 9514
      to_port         = 9514
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
    }
  ingress {
      description     = "Access to the managed server from workspace"
      from_port       = 9514
      to_port         = 9514
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-ManagementCIDR
    }
  ingress {
      description     = "Database connections to rds apex edw and mojfin"
      from_port       = 1521
      to_port         = 1521
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
    }
  ingress {
      description     = "LDAP Server Connection"
      from_port       = 1389
      to_port         = 1389
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
    }

  egress {
      description     = "Access from Bastion via SSH. Requires all access."
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"]
    }
  egress {
      description     = "access to the admin server"
      from_port       = 9500
      to_port         = 9500
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
    }
  egress {
      description     = "Access to the admin server from workspace"
      from_port       = 9500
      to_port         = 9500
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-ManagementCIDR
    }
  egress {
      description     = "Access to the managed server"
      from_port       = 9502
      to_port         = 9502
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
    }
  egress {
      description     = "Access to the managed server from workspace"
      from_port       = 9502
      to_port         = 9502
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-ManagementCIDR
    }
  egress {
      description     = "Access to the managed server"
      from_port       = 9514
      to_port         = 9514
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
    }
  egress {
      description     = "Access to the managed server from workspace"
      from_port       = 9514
      to_port         = 9514
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-ManagementCIDR
    }
  egress {
      description     = "Database connections from rds apex edw and mojfin"
      from_port       = 1521
      to_port         = 1521
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
    }
  egress {
      description     = "LDAP Server Connection"
      from_port       = 1389
      to_port         = 1389
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
    }
  }

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_name}-S3-local.application_data.accounts[local.environment].bucketname-RW-ec2-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  #NO NAME in CF CODE name = "${local.application_name}-ec2-instance-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
  managed_policy_arns = [aws_iam_policy.CloudWatchAgentServerPolicy.arn, aws_iam_policy.AmazonSSMFullAccess.arn]
}
EOF
}

resource "aws_iam_role_policy" "ec2_instance_policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name}-ec2-policy"
  role = aws_iam_role.ec2_instance_role.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action":
                "s3:ListBucket"
            "Resource": "arn:aws:s3:::laa-software-library",
                        "arn:aws:s3:::laa-software-library/*",
        },
        {
            "Effect": "Allow",
            "Action":
                "s3:GetObject"
            "Resource": "arn:aws:s3:::laa-software-library/*",
        },
        # {
        #     "Effect": "Allow",
        #     "Action":
        #         "secretsmanager:GetSecretValue"
        #     "Resource": "arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:${pAppName}/app/*",
        # },
        {
            "Effect": "Allow",
            "Action":
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:PutRetentionPolicy",
                "logs:PutLogEvents",
                "ec2:DescribeInstances",
            "Resource": "*",
        },
        {
            "Effect": "Allow",
            "Action":
                "ec2:CreateTags",
            "Resource": "*",
        },
    ]
}
EOF
}

resource "aws_ebs_volume" "EC2ServeVolume01" {
  availability_zone = "eu-west-2a"
  size = local.application_data.accounts[local.environment].01orahomesize
  type = "gp3"
  encrypted = false

  tags = merge(
    local.tags,
    { "Name" = "${var.oas_app_name???}-EC2ServeVolume01" },
  )

  lifecycle {
    ignore_changes = [
      snapshot_id,
    ]
  }
}

resource "aws_volume_attachment" "oas_EC2ServeVolume01" {
  device_name = "/dev/???"
  volume_id   = aws_ebs_volume.EC2ServeVolume01.id
  instance_id = aws_instance.oas_app_instance.id
}

resource "aws_ebs_volume" "EC2ServeVolume02" {
  availability_zone = "eu-west-2a"
  size = local.application_data.accounts[local.environment].02stageesize
  type = "gp3"
  encrypted = false

  tags = merge(
    local.tags,
    { "Name" = "${var.oas_app_name???}-EC2ServeVolume02" },
  )

  lifecycle {
    ignore_changes = [
      snapshot_id,
    ]
  }
}

resource "aws_volume_attachment" "oas_EC2ServeVolume02" {
  device_name = "/dev/???"
  volume_id   = aws_ebs_volume.EC2ServeVolume02.id
  instance_id = aws_instance.oas_app_instance.id
}