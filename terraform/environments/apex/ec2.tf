# locals {
#   instance-userdata = <<EOF
# #!/bin/bash
# cd /tmp
# yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
# sudo systemctl start amazon-ssm-agent
# sudo systemctl enable amazon-ssm-agent
# echo "${aws_efs_file_system.efs.dns_name}:/ /backups nfs4 rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport" >> /etc/fstab
# mount -a

# # Setting up CloudWatch Agent
# echo '${data.local_file.cloudwatch_agent.content}' > cloudwatch_agent_config.json
# /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:cloudwatch_agent_config.json
# EOF
# }

resource "aws_instance" "apex_db_instance" {
  ami                         = local.application_data.accounts[local.environment].ec2amiid
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.id
  user_data                   = "${file("run.sh")}"

  root_block_device {
    delete_on_termination = false
    encrypted             = true # TODO Confirm if encrypted volumes can work for OAS, as it looks like in MP they must be encrypted
    volume_size           = 60
    volume_type           = "gp2"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}db-ec2-root" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} Database Server" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}

# data "local_file" "cloudwatch_agent" {
#   filename = "${path.module}/cloudwatch_agent_config.json"
# }

resource "aws_security_group" "ec2" {
  name        = local.application_name
  description = "APEX DB Server Security Group"
  vpc_id      = data.aws_vpc.shared.id

  # this ingress rule to be added after the ECS has been setup in MP
  # ingress {
  #   description = "database listener port access to ECS security group"
  #   from_port   = 1521
  #   to_port     = 1521
  #   protocol    = "tcp"
  #   security_groups = aws_security_group.<ECS_SG>.id #!Ref AppEcsSecurityGroup
  # }

  ingress {
    description = "database listener port access to lz non prod mgmt cidr"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].lz_shared_nonprod_mgmt_vpc_cidr]
  }
  ingress {
    description = "database listener port access to lz prod mgmt cidr"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].lz_shared_prod_mgmt_vpc_cidr]
  }
  ingress {
    description = "database listener port access to MP development CIDR"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].mp_vpc_cidr]
  }

  egress {
    description = "Allow AWS SSM Session Manager"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "outbound access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_name}-ec2-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  name                = "${local.application_name}-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy", "arn:aws:iam::aws:policy/AmazonSSMFullAccess"]
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
  name = "${local.application_name}-ec2-policy"
  role = aws_iam_role.ec2_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutRetentionPolicy",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:DescribeInstances",
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateTags"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_ebs_volume" "u01-orahome" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].u01_orahome_size
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].u01_orahome_snapshot
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}db-ec2-u01-orahome" },
  )
}
resource "aws_volume_attachment" "u01-orahome" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.u01-orahome.id
  instance_id = aws_instance.apex_db_instance.id
}

resource "aws_ebs_volume" "u02-oradata" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].u02_oradata_size
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].u02_oradata_snapshot
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}db-ec2-u02-oradata" },
  )
}



resource "aws_volume_attachment" "u02-oradata" {
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.u02-oradata.id
  instance_id = aws_instance.apex_db_instance.id
}

resource "aws_ebs_volume" "u03-redo" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].u03_redo_size
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].u03_redo_snapshot
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}db-ec2-u03-redo" },
  )
}
resource "aws_volume_attachment" "u03-redo" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.u03-redo.id
  instance_id = aws_instance.apex_db_instance.id
}

resource "aws_ebs_volume" "u04-arch" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].u04_arch_size
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].u04_arch_snapshot
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}db-ec2-u04-arch" },
  )
}
resource "aws_volume_attachment" "u04-arch" {
  device_name = "/dev/sde"
  volume_id   = aws_ebs_volume.u04-arch.id
  instance_id = aws_instance.apex_db_instance.id
}

resource "aws_route53_record" "apex-db" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.inner.zone_id
  name     = "db.${local.application_name}.${data.aws_route53_zone.inner.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.apex_db_instance.private_ip]
}






