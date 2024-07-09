
####### EC2 Role #######
resource "aws_iam_role" "edw_ec2_role" {
  name = "${local.application_name}-ec2-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = ["ec2.amazonaws.com"] }
      Action    = ["sts:AssumeRole"]
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  path = "/"

  inline_policy {
    name = "${local.application_name}-ec2-policy"
    policy = jsonencode({
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:ListBucket"]
          Resource = ["arn:aws:s3:::laa-software-library", "arn:aws:s3:::laa-software-library/*"]
        },
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject"]
          Resource = ["arn:aws:s3:::laa-software-library/*"]
        },
        {
          Effect   = "Allow"
          Action   = ["secretsmanager:GetSecretValue"]
          Resource = ["arn:aws:secretsmanager:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:secret:${local.application_name}/app/*"]
        },
        {
          Effect   = "Allow"
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:DescribeLogStreams", "logs:PutRetentionPolicy", "logs:PutLogEvents", "ec2:DescribeInstances"]
          Resource = ["*"]
        },
        {
          Effect   = "Allow"
          Action   = ["ec2:CreateTags"]
          Resource = ["*"]
        },
      ]
    })
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-instance-role"
    }
  )
}


####### DB Instance Profile #######

resource "aws_iam_instance_profile" "edw_ec2_instance_profile" {
  name = "${local.application_name}-S3-${local.application_data.accounts[local.environment].edw_bucket_name}-edw-RW-ec2-profile"
  path = "/"
  role = aws_iam_role.edw_ec2_role.name

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-instance-profile"
    }
  )
}

####### DB Instance #######

resource "aws_key_pair" "edw_ec2_key" {
  key_name   = "${local.application_name}-ssh-key"
  public_key = local.application_data.accounts[local.environment].edw_ec2_key
}

resource "aws_instance" "edw_db_instance" {
  ami                    = local.application_data.accounts[local.environment].edw_ec2_ami_id
  availability_zone      = "eu-west-2a"
  instance_type          = local.application_data.accounts[local.environment].edw_ec2_instance_type
  iam_instance_profile   = aws_iam_instance_profile.edw_ec2_instance_profile.id
  key_name               = aws_key_pair.edw_ec2_key.key_name
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [aws_security_group.edw_db_security_group.id]
  user_data = base64encode(templatefile("edw-ec2-user-data.sh", {
    edw_app_name         = local.application_data.accounts[local.environment].edw_AppName
    edw_dns_extension    = local.application_data.accounts[local.environment].edw_dns_extension
    edw_environment      = local.application_data.accounts[local.environment].edw_environment
    edw_region           = local.application_data.accounts[local.environment].edw_region
    edw_ec2_role         = aws_iam_role.edw_ec2_role.name
    edw_s3_backup_bucket = local.application_data.accounts[local.environment].edw_s3_backup_bucket
    edw_cis_ip           = local.application_data.accounts[local.environment].edw_cis_ip
    edw_eric_ip          = local.application_data.accounts[local.environment].edw_eric_ip
    edw_ccms_ip          = local.application_data.accounts[local.environment].edw_ccms_ip
  }))


  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = local.application_data.accounts[local.environment].edw_root_volume_size
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}-root-volume" },
    )
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_data.accounts[local.environment].database_ec2_name}"
    }
  )
}

####### DB Volumes #######

resource "aws_ebs_volume" "orahomeVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_OrahomeVolumeSize
  encrypted         = true
  type              = "gp3"

  tags = {
    Name = "${local.application_data.accounts[local.environment].edw_AppName}-orahome"
  }
}

resource "aws_volume_attachment" "orahomeVolume-attachment" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.orahomeVolume.id
  instance_id = aws_instance.edw_db_instance.id
}

resource "aws_ebs_volume" "oratempVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_OratempVolumeSize
  encrypted         = true
  type              = "gp3"

  tags = {
    Name = "${local.application_data.accounts[local.environment].edw_AppName}-oraredo"
  }
}

resource "aws_volume_attachment" "oratempVolume-attachment" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.oratempVolume.id
  instance_id = aws_instance.edw_db_instance.id
}

resource "aws_ebs_volume" "oradataVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_OradataVolumeSize
  encrypted         = true
  type              = "gp3"

  tags = {
    Name = "${local.application_data.accounts[local.environment].edw_AppName}-oradata"
  }
}

resource "aws_volume_attachment" "oradataVolume-attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.oradataVolume.id
  instance_id = aws_instance.edw_db_instance.id
}

resource "aws_ebs_volume" "softwareVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_SoftwareVolumeSize
  encrypted         = true
  type              = "gp3"

  tags = {
    Name = "${local.application_data.accounts[local.environment].edw_AppName}-software"
  }
}

resource "aws_volume_attachment" "softwareVolume-attachment" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.softwareVolume.id
  instance_id = aws_instance.edw_db_instance.id
}

resource "aws_ebs_volume" "ArchiveVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_ArchiveVolumeSize
  encrypted         = true
  type              = "gp3"

  tags = {
    Name                                               = "${local.application_data.accounts[local.environment].edw_AppName}-oraarch"
    "dlm:snapshot-with:volume-hourly-35-day-retention" = "yes"
  }
}

resource "aws_volume_attachment" "ArchiveVolume-attachment" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ArchiveVolume.id
  instance_id = aws_instance.edw_db_instance.id
}


####### DB Security Groups #######

resource "aws_security_group" "edw_db_security_group" {
  name        = "${local.application_name} Security Group"
  description = "Security Group for DB EC2 instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-security-group"
    }
  )

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].edw_management_cidr]
    description = "SSH access"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
    description = "SSH access"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].edw_bastion_ssh_cidr]
    description = "SSH access"
  }

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
    description = "RDS env access"
  }

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].edw_management_cidr]
    description = "RDS Workspace access"
  }

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["10.200.96.0/19"]
    description = "RDS Ireland Workspace access"
  }

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["10.200.32.0/19"]
    description = "RDS Appstream access"
  }
}

###### DB DNS #######

resource "aws_route53_record" "edw_internal_dns_record" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.application_name}.${data.aws_route53_zone.external.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.edw_db_instance.private_ip]
}