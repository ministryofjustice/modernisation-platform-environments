# ECS CloudWatch Logs
resource "aws_kms_key" "ecs-logs" {
  description             = "KMS key for ${local.application_name_short} ECS CloudWatch log group"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = local.tags
}

resource "aws_kms_key_policy" "ecs-logs" {
  key_id = aws_kms_key.ecs-logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Root"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.environment_management.account_ids["${local.application_name}-${local.environment}"]}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.eu-west-2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "ecs-logs" {
  name          = "alias/${local.application_name_short}-${local.environment}-ecs-logs"
  target_key_id = aws_kms_key.ecs-logs.key_id
}

# EFS 
resource "aws_kms_key" "efs" {
  description             = "KMS key for ${local.application_name_short} ${local.environment} EFS encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = local.tags
}

resource "aws_kms_key_policy" "efs" {
  key_id = aws_kms_key.efs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Root"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.environment_management.account_ids["${local.application_name}-${local.environment}"]}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "efs" {
  name          = "alias/${local.application_name_short}-${local.environment}-efs"
  target_key_id = aws_kms_key.efs.key_id
}

# ECR
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ${local.application_name_short} ${local.environment} ECR encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = local.tags
}

resource "aws_kms_key_policy" "ecr" {
  key_id = aws_kms_key.ecr.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Root"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.environment_management.account_ids["${local.application_name}-${local.environment}"]}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${local.application_name_short}-${local.environment}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}