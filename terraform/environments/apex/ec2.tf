resource "aws_key_pair" "apex" {
  key_name   = "${local.application_name}-ssh-key"
  public_key = local.application_data.accounts[local.environment].apex_ec2_key
}

resource "aws_instance" "apex_db_instance" {
  ami                         = local.application_data.accounts[local.environment].ec2amiid
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  vpc_security_group_ids      = [aws_security_group.database.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.id
  key_name                    = aws_key_pair.apex.key_name
  user_data_base64            = base64encode(local.database-instance-userdata)
  user_data_replace_on_change = true

  lifecycle {
    ignore_changes = [user_data_base64, user_data_replace_on_change]
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = true # TODO Confirm if encrypted volumes can work for OAS, as it looks like in MP they must be encrypted
    volume_size           = 60
    volume_type           = "gp2"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}db-ec2-root" },
      { "backup" = "false" }
    )
  }

  tags = merge(
    local.tags,
    { "Name" = local.database_ec2_name },
    { "instance-scheduling" = "skip-scheduling" },
    { "backup" = "false" },
    local.backup_schedule_tags
  )
}

data "local_file" "cloudwatch_agent" {
  filename = "${path.module}/cloudwatch_agent_config.json"
}


resource "aws_security_group" "database" {
  name        = "${local.application_name}-db-security-group"
  description = "APEX DB Server Security Group"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-db-security-group" }
  )

}

resource "aws_vpc_security_group_ingress_rule" "db_ecs" {
  security_group_id            = aws_security_group.database.id
  description                  = "Allow ECS to access database instance"
  referenced_security_group_id = module.apex-ecs.cluster_ec2_security_group_id
  from_port                    = 1521
  ip_protocol                  = "tcp"
  to_port                      = 1521
}

resource "aws_vpc_security_group_ingress_rule" "db_mp_vpc" {
  security_group_id = aws_security_group.database.id
  description       = "Allow MP VPC (OAS) to access database instance"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
  from_port         = 1521
  ip_protocol       = "tcp"
  to_port           = 1521
}

resource "aws_vpc_security_group_ingress_rule" "db_lambda" {
  security_group_id            = aws_security_group.database.id
  description                  = "Allow Lambda SSH access for backup snapshots"
  referenced_security_group_id = aws_security_group.backup_lambda.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "db_bastion" {
  security_group_id            = aws_security_group.database.id
  description                  = "Allow Bastion SSH access"
  referenced_security_group_id = module.bastion_linux.bastion_security_group
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "db_workspace" {
  security_group_id = aws_security_group.database.id
  description       = "Database listener port access to Workspaces"
  cidr_ipv4         = local.application_data.accounts[local.environment].workspace_cidr
  from_port         = 1521
  ip_protocol       = "tcp"
  to_port           = 1521
}

# This is a temp rule whilst OAS resides in LZ
resource "aws_vpc_security_group_ingress_rule" "oas_lz" {
  security_group_id = aws_security_group.database.id
  description       = "Allow OAS in LZ to access APEX"
  cidr_ipv4         = local.application_data.accounts[local.environment].oas_lz_cidr
  from_port         = 1521
  ip_protocol       = "tcp"
  to_port           = 1521
}

resource "aws_vpc_security_group_egress_rule" "db_outbound" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
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
    { "backup" = "false" }
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
    { "backup" = "false" }
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
    { "backup" = "false" }
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
    { "backup" = "false" }
  )
}
resource "aws_volume_attachment" "u04-arch" {
  device_name = "/dev/sde"
  volume_id   = aws_ebs_volume.u04-arch.id
  instance_id = aws_instance.apex_db_instance.id
}

resource "aws_route53_record" "apex-db" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.db_hostname}.${data.aws_route53_zone.external.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.apex_db_instance.private_ip]
}

resource "aws_cloudwatch_log_group" "database" {
  name              = "${upper(local.application_name)}-EC2-database-alert"
  retention_in_days = 0
  # kms_key_id = aws_kms_key.cloudwatch_logs_key.arn # Not encrypted in LZ
  tags = merge(
    local.tags,
    {
      Name = "${upper(local.application_name)}-EC2-database-alert"
    }
  )
}

resource "aws_cloudwatch_log_metric_filter" "database" {
  name           = "${upper(local.application_name)}-LogMetricOracleAlerts"
  pattern        = "\"ORA-\""
  log_group_name = aws_cloudwatch_log_group.database.name

  metric_transformation {
    name          = "${upper(local.application_name)}-LogMetricOracleAlerts"
    namespace     = "LogsMetricFilters"
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_group" "pmon_status" {
  name              = "${upper(local.application_name)}-EC2-database-pmon-status"
  retention_in_days = 0
  # kms_key_id = aws_kms_key.cloudwatch_logs_key.arn # Not encrypted in LZ
  tags = merge(
    local.tags,
    {
      Name = "${upper(local.application_name)}-EC2-database-pmon-status"
    }
  )
}

resource "aws_cloudwatch_log_metric_filter" "pmon_status" {
  name           = "${upper(local.application_name)}-LogMetricPMONStatus"
  pattern        = "DOWN"
  log_group_name = aws_cloudwatch_log_group.pmon_status.name

  metric_transformation {
    name          = "${upper(local.application_name)}-LogMetricPMONStatus"
    namespace     = "LogsMetricFilters"
    value         = "1"
    default_value = 0
  }
}





