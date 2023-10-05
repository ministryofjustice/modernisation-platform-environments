locals {
  instance-userdata = <<EOF
#!/bin/bash
cd /tmp
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
echo "fs-04977da5fb1325b4b.efs.eu-west-2.amazonaws.com:/ /backups nfs4 rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport" >> /etc/fstab
mount -a
mount_status=$?
while [[ $mount_status != 0 ]]
do
  sleep 10
  mount -a
  mount_status=$?
done
EOF
}

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
  user_data_base64            = base64encode(local.instance-userdata)

  root_block_device {
    delete_on_termination = false
    encrypted             = true # TODO Confirm if encrypted volumes can work for OAS, as it looks like in MP they must be encrypted
    volume_size           = 60
    volume_type           = "gp2"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}-root-volume" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} Database Server" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}

resource "aws_security_group" "ec2" {
  name        = local.application_name
  description = "APEX DB Server Security Group"
  vpc_id      = data.aws_vpc.shared.id

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
    cidr_blocks = [local.application_data.accounts[local.environment].mp_vpc_cidr] #!ImportValue env-VpcCidr
  }
  # ingress {
  #   description = "Ingress from Migration server Security Group - This should be reviewed"
  #   from_port   = 1521
  #   to_port     = 1521
  #   protocol    = "tcp"
  #   security_groups = sg-8fddd6e7 #sg-migrationgw
  # }
  # ingress {
  #   description = "Ingress from RC depending on Environment"
  #   from_port   = 1521
  #   to_port     = 1521
  #   protocol    = "tcp"
  #   cidr_blocks = ["172.16.4.0/20"]
  # }

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
  #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name}-ec2-policy"
  role = aws_iam_role.ec2_instance_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # {
      #   Action = [
      #     "ec2:Describe*",
      #   ]
      #   Effect   = "Allow"
      #   Resource = "*"
      # },
      # {
      #   Effect = "Allow",
      #   Action = [
      #     "s3:ListBucket",
      #   ],
      #   Resource = [
      #     "arn:aws:s3:::modernisation-platform-software20230224000709766100000001",
      #     "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*",
      #   ]
      # },
      # {
      #   Effect = "Allow",
      #   Action = [
      #     "s3:GetObject"
      #   ],
      #   Resource = [
      #     "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*",
      #   ]
      # },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutRetentionPolicy",
          "logs:PutLogEvents",
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

# resource "aws_ebs_volume" "EC2ServerVolumeORAHOME" {
#   availability_zone = "eu-west-2a"
#   size              = local.application_data.accounts[local.environment].orahomesize
#   type              = "gp3"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].orahome_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-EC2ServerVolumeORAHOME" },
#   )
# }

# resource "aws_volume_attachment" "oas_EC2ServerVolume01" {
#   device_name = "/dev/sdb"
#   volume_id   = aws_ebs_volume.EC2ServerVolumeORAHOME.id
#   instance_id = aws_instance.oas_app_instance.id
# }

resource "aws_route53_record" "apex-db" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.inner.zone_id
  # name     = "${local.application_name}.${data.aws_route53_zone.inner.name}"
  name     = "db.${local.application_name}.${data.aws_route53_zone.inner.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.apex_db_instance.private_ip]
}
