##############################################
### KMS Key for EBS Volume Encryption
### Used for encrypting WorkSpaces volumes
##############################################

resource "aws_kms_key" "ebs" {

  description             = "KMS key for EBS volume encryption in ${local.application_name}-${local.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-ebs-kms"
    }
  )
}

resource "aws_kms_alias" "ebs" {

  name          = "alias/${local.application_name}-${local.environment}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

##############################################
### KMS Key Policy
##############################################

resource "aws_kms_key_policy" "ebs" {

  key_id = aws_kms_key.ebs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow WorkSpaces to use the key"
        Effect = "Allow"
        Principal = {
          Service = "workspaces.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow WorkSpaces DefaultRole to use the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/workspaces_DefaultRole"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key for EBS encryption"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.eu-west-2.amazonaws.com"
          }
        }
      }
    ]
  })
}
