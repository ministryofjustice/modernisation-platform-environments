# AWS Transfer Service

locals {
  transfer_secret_json_list = local.build_transfer ? try(
    jsondecode(data.aws_secretsmanager_secret_version.transfer_service_secret_version[0].secret_string),
    []
  ) : []

  transfer_users = [
    for obj in local.transfer_secret_json_list : {
      username      = tostring(obj.username)
      public_key    = obj.public_key
      folder        = obj.folder
      bucket_name   = obj.bucket_name
      ingress_cidrs = obj.ingress_cidrs
    }
  ]
}

resource "aws_iam_role" "transfer_role" {
  count = local.build_transfer ? 1 : 0
  name  = "transfer-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "transfer_policy" {
  count = local.build_transfer ? 1 : 0
  name  = "transfer-access-policy"
  role  = aws_iam_role.transfer_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      [
        for user in local.transfer_users : {
          Sid    = "S3AccessFor-${user.username}"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::${user.bucket_name}",
            "arn:aws:s3:::${user.bucket_name}/${user.folder}"
          ]
          Condition = length(user.ingress_cidrs) > 0 ? {
            IpAddress = {
              "aws:SourceIp" = user.ingress_cidrs
            }
          } : null
        }
      ],
      [
        {
          Sid    = "KMSAccess"
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Resource = local.laa_general_kms_arn
        }
      ]
    )
  })
}

resource "aws_transfer_server" "transfer_service_server" {
  count                     = local.build_transfer ? 1 : 0
  endpoint_type             = "PUBLIC"
  identity_provider_type    = "SERVICE_MANAGED"
  security_policy_name      = "TransferSecurityPolicy-SshAuditCompliant-2025-02"

  protocols = ["SFTP"]

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-xhibit-transfer-service"
    }
  )
}

resource "aws_transfer_user" "transfer_user" {
  count         = local.build_transfer ? length(local.transfer_users) : 0
  server_id     = aws_transfer_server.transfer_service_server[0].id
  user_name     = local.transfer_users[count.index].username
  role          = aws_iam_role.transfer_role[0].arn
  home_directory = local.transfer_users[count.index].folder

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-xhibit-${local.transfer_users[count.index].username}"
    }
  )
}

resource "aws_transfer_ssh_key" "transfer_user_key" {
  count     = local.build_transfer ? length(local.transfer_users) : 0
  server_id = aws_transfer_server.transfer_service_server[0].id
  user_name = aws_transfer_user.transfer_user[count.index].user_name
  body      = local.transfer_users[count.index].public_key
}

