resource "aws_efs_file_system" "edw" {

  performance_mode = "maxIO"
  throughput_mode  = "bursting"
  encrypted  = "true"
  kms_key_id = aws_kms_key.efs.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_90_DAYS"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-EFS" }
  )

}

resource "aws_efs_backup_policy" "edw" {
  file_system_id = aws_efs_file_system.edw.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_kms_key" "efs" {
  description = "KMS key for encrypting EFS"
  #   deletion_window_in_days = 10
  enable_key_rotation = true
  tags                = local.tags
}

resource "aws_kms_key_policy" "efs" {
  key_id = aws_kms_key.efs.id
  policy = jsonencode({
    Id = "EFSKMSPolicy"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:root"
        }

        Resource = "*"
        Sid      = "Allow administration of the key"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_kms_alias" "efs" {
  name          = "alias/${local.application_name}-efs-kms"
  target_key_id = aws_kms_key.efs.key_id
}


### Only allow access from Subnet A matching Landing Zone
resource "aws_efs_mount_target" "target_a" {

  file_system_id  = aws_efs_file_system.edw.id
  subnet_id       = data.aws_subnet.data_subnets_a.id
  security_groups = [aws_security_group.efs.id]
}


resource "aws_security_group" "efs" {
  name        = "${local.application_name}-${local.environment}-efs-security-group"
  description = "EDW EFS Mount Target Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_egress_rule" "efs_outbound" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
  description       = "EFS Rule inbound from local VPC"
  from_port         = 2049
  ip_protocol       = "tcp"
  to_port           = 2049
}

resource "aws_vpc_security_group_ingress_rule" "efs_inbound" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
  description       = "EFS Rule outbound to local VPC"
  from_port         = 2049
  ip_protocol       = "tcp"
  to_port           = 2049
}

resource "aws_cloudwatch_metric_alarm" "efs_connection_repo_home" {
  alarm_name          = "${local.application_name}-${local.environment}-efs-connection"
  alarm_description   = "If the instance has lost connection with its EFS system, please investigate."
  comparison_operator = "LessThanThreshold"
  dimensions = {
    FileSystemId = aws_efs_file_system.edw.id
  }
  evaluation_periods = "3"
  metric_name        = "ClientConnections"
  namespace          = "AWS/EFS"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.environment == "production" ? 4 : 3
  alarm_actions      = [aws_sns_topic.edw.arn]
  ok_actions         = [aws_sns_topic.edw.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-efs-connection"
    }
  )
}