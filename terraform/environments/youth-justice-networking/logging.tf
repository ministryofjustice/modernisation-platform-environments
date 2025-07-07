# Configure log groups for CloudWatch

locals {
  log_groups = {
    "yjaf-juniper/OSSecurity" = 400
    "yjaf-juniper/OSSystem"   = 400
    "yjaf-juniper/clamav"     = 400
    "yjaf-juniper/rsyslog"    = 400
  }
}

resource "aws_cloudwatch_log_group" "yjaf_logs" {
  for_each          = local.log_groups
  name              = each.key
  retention_in_days = each.value
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
}

resource "aws_iam_role" "yjb_juniper_ec2_role" {
  name = "YJBJuniperEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_kms_key" "cloudwatch_logs" {
  description         = "KMS key for CloudWatch log group encryption"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Allow account use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs use of the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

# Create instance profile for syslog server

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.yjb_juniper_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attach" {
  role       = aws_iam_role.yjb_juniper_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "yjb_juniper_instance_profile" {
  name = "YJBJuniperInstanceProfile"
  role = aws_iam_role.yjb_juniper_ec2_role.name
}
