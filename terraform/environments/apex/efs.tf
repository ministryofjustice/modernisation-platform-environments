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
  name          = "alias/${local.application_name}-efs-kms"
  target_key_id = aws_kms_key.efs.key_id
}

#########################################
## Migrating EFS data from Backup
#########################################
# import {
#   to = aws_efs_file_system.efs
#   id = "fs-0ca2e956f29511d3c"
# }
#########################################

resource "aws_efs_file_system" "efs" {
  encrypted        = true
  kms_key_id       = aws_kms_key.efs.arn
  performance_mode = "maxIO"
  throughput_mode  = "bursting"

  tags = merge(
    local.tags,
    { "Name" = "mp-${local.application_name}-efs" }
  )

  lifecycle_policy {
    transition_to_ia = "AFTER_90_DAYS"
  }
}

resource "aws_security_group" "efs_product" {
  name        = "${local.application_name}-${local.environment}-efs-security-group"
  description = "Apex Product EFS Security Group"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-efs-security-group" }
  )
}

resource "aws_vpc_security_group_egress_rule" "efs_product_outbound" {
  security_group_id            = aws_security_group.efs_product.id
  description                  = "EFS Rule outbound for instance"
  referenced_security_group_id = aws_security_group.database.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}

resource "aws_vpc_security_group_ingress_rule" "efs_product_inbound" {
  security_group_id            = aws_security_group.efs_product.id
  description                  = "EFS Rule inbound for instance"
  referenced_security_group_id = aws_security_group.database.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
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