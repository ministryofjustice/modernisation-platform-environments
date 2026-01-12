############################
# ec2.tf
############################

locals {
  db_userdata = <<-EOF
#!/bin/bash
exec > /var/log/userdata.log 2>&1
set -x

yum -y update || true
yum -y install unzip || true

hostname edw
sed -i '1s/.*/edw/' /etc/hostname || true

EOF
}

####### IAM roles #######

resource "aws_iam_role" "edw_ec2_role" {
  name = "${local.application_name}-ec2-instance-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-role"
    }
  )
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

###### DB Instance Profile ########

resource "aws_iam_instance_profile" "edw_ec2_instance_profile" {
  name = "${local.application_name}-S3-${local.application_data.accounts[local.environment].edw_bucket_name}-edw-RW-ec2-profile"
  role = aws_iam_role.edw_ec2_role.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-profile"
    }
  )
}

####### DB Policy #######

resource "aws_iam_policy" "edw_ec2_role_policy" {
  name = "${local.application_name}-ec2-policy2"
  path = "/"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-policy"
    }
  )

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadSoftwareLibrary",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::laa-software-library",
        "arn:aws:s3:::laa-software-library/*"
      ]
    },
    {
      "Sid": "CloudWatchLogging",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogStreams",
        "logs:PutRetentionPolicy",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowTagging",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


####### DB Policy attachments ########

resource "aws_iam_role_policy_attachment" "edw_cw_agent_policy_attachment" {
  role       = aws_iam_role.edw_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "edw_ec2_policy_attachments" {
  role       = aws_iam_role.edw_ec2_role.name
  policy_arn = aws_iam_policy.edw_ec2_role_policy.arn
}

####### DB Instance #######

resource "aws_key_pair" "edw_ec2_key" {
  key_name   = "${local.application_name}-ssh-key"
  public_key = local.application_data.accounts[local.environment].edw_ec2_key
}

resource "aws_instance" "edw_db_instance" {
  ami                         = local.application_data.accounts[local.environment].edw_ec2_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].edw_ec2_instance_type
  iam_instance_profile        = aws_iam_instance_profile.edw_ec2_instance_profile.id
  key_name                    = aws_key_pair.edw_ec2_key.key_name
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids      = [aws_security_group.edw_db_security_group.id]
  user_data_base64            = base64encode(local.db_userdata)
  user_data_replace_on_change = true

  root_block_device {
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}-root-volume" }
    )
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2

    http_tokens = "required"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    { "Name" = local.application_data.accounts[local.environment].database_ec2_name },
    { "instance-scheduling" = "skip-scheduling" }
  )
}

####### DB Volumes #######

resource "aws_ebs_volume" "orahomeVolume" {
  availability_zone = "${local.application_data.accounts[local.environment].edw_region}a"
  size              = local.application_data.accounts[local.environment].edw_OrahomeVolumeSize
  encrypted         = true
  type              = "gp3"
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id

  lifecycle { ignore_changes = [kms_key_id] }

  tags = { Name = "${local.application_name}-orahome" }
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
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id

  lifecycle { ignore_changes = [kms_key_id] }

  tags = { Name = "${local.application_name}-oraredo" }
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
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id

  lifecycle { ignore_changes = [kms_key_id] }

  tags = { Name = "${local.application_name}-oradata" }
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
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id

  lifecycle { ignore_changes = [kms_key_id] }

  tags = { Name = "${local.application_name}-software" }
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
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id

  lifecycle { ignore_changes = [kms_key_id] }

  tags = {
    Name = "${local.application_name}-oraarch"
  }
}

resource "aws_volume_attachment" "ArchiveVolume-attachment" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ArchiveVolume.id
  instance_id = aws_instance.edw_db_instance.id
}

######## DB Security Groups #######

resource "aws_security_group" "edw_db_security_group" {
  name        = "${local.application_name}-Security Group"
  description = "Security Group for DB EC2 instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.application_name}-security-group"
  })
}

# SSH from Bastion
resource "aws_vpc_security_group_ingress_rule" "db_bastion_ssh" {
  security_group_id            = aws_security_group.edw_db_security_group.id
  description                  = "SSH from the Bastion"
  referenced_security_group_id = module.bastion_linux.bastion_security_group
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}