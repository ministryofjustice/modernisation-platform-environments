resource "aws_kms_key" "efs" {
  description = "KMS key for encrypting EFS"
  # enable_key_rotation = true
  tags = local.tags
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
  name          = "alias/${local.application_name_short}-efs-kms"
  target_key_id = aws_kms_key.efs.key_id
}

resource "aws_efs_file_system" "efs" {
  encrypted        = true
  kms_key_id       = aws_kms_key.efs.arn
  performance_mode = "maxIO"
  throughput_mode  = "bursting"

  tags = merge(
    local.tags,
    { "Name" = "mp-${local.application_name_short}-efs" }
  )

  lifecycle_policy {
    transition_to_ia = "AFTER_90_DAYS"
  }
}

resource "aws_security_group" "efs_product" {
  name        = "${local.application_name_short}-${local.environment}-efs-security-group"
  description = "Apex Product EFS Security Group"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short}-${local.environment}-efs-security-group" }
  )
}

resource "aws_security_group_rule" "efs_product_outbound" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs_product.id
  source_security_group_id = aws_security_group.ec2_instance_sg.id
  description              = "Allow outbound to CIS Instance SG"
}

resource "aws_security_group_rule" "efs_product_outbound" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs_product.id
  source_security_group_id = aws_security_group.ec2_instance_sg.id
  description              = "Allow inbound from CIS Instance SG"
}

resource "aws_efs_mount_target" "subnet_a" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.data_subnets_a.id
  security_groups = [aws_security_group.efs_product.id]
}

resource "aws_efs_mount_target" "subnet_b" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.data_subnets_b.id
  security_groups = [aws_security_group.efs_product.id]
}

resource "aws_efs_mount_target" "subnet_c" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.data_subnets_c.id
  security_groups = [aws_security_group.efs_product.id]
}

resource "aws_efs_backup_policy" "efs_backup_policy" {
  file_system_id = aws_efs_file_system.efs.id

  backup_policy {
    status = "ENABLED"
  }
}

# resource "aws_cloudwatch_metric_alarm" "efs_connection_repo_home" {
#   alarm_name          = "${local.application_name_short}-${local.environment}-efs-connection"
#   alarm_description   = "If the instance has lost connection with its EFS system, please investigate."
#   comparison_operator = "LessThanThreshold"
#   dimensions = {
#     FileSystemId = aws_efs_file_system.efs.id
#   }
#   evaluation_periods = "3"
#   metric_name        = "ClientConnections"
#   namespace          = "AWS/EFS"
#   period             = "60"
#   statistic          = "Sum"
#   threshold          = local.environment == "production" ? 4 : 3
#   alarm_actions      = [aws_sns_topic.cis.arn]
#   ok_actions         = [aws_sns_topic.cis.arn]
#   treat_missing_data = "breaching"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name_short}-${local.environment}-efs-connection"
#     }
#   )
# }