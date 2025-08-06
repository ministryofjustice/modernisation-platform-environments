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
    Statement = flatten([
      [
        for idx in range(length(local.transfer_users)) : [
          {
            Sid    = "S3Access${substr(md5(local.transfer_users[idx].username), 0, 10)}"
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:DeleteObject"
            ]
            Resource = [
              "arn:aws:s3:::${local.transfer_users[idx].bucket_name}/${trim(local.transfer_users[idx].folder, "/")}/*"
            ]
            Condition = length(local.transfer_users[idx].ingress_cidrs) > 0 ? {
              IpAddress = {
                "aws:SourceIp" = local.transfer_users[idx].ingress_cidrs
              }
            } : null
          },
          {
            Sid    = "S3List${substr(md5(local.transfer_users[idx].username), 0, 10)}"
            Effect = "Allow"
            Action = "s3:ListBucket"
            Resource = "arn:aws:s3:::${local.transfer_users[idx].bucket_name}"
            Condition = merge(
              {
                StringLike = {
                  "s3:prefix" = "${trim(local.transfer_users[idx].folder, "/")}/*"
                }
              },
              length(local.transfer_users[idx].ingress_cidrs) > 0 ? {
                IpAddress = {
                  "aws:SourceIp" = local.transfer_users[idx].ingress_cidrs
                }
              } : {}
            )
          }
        ]
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
    ])
  })
}

# Logging role and policy

resource "aws_iam_role" "transfer_logging" {
  name = "transfer-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "transfer.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "transfer-logging-role"
  }
}

resource "aws_iam_role_policy" "transfer_logging_policy" {
  name = "transfer-logging-policy"
  role = aws_iam_role.transfer_logging.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}



resource "aws_transfer_server" "transfer_service_server" {
  count                     = local.build_transfer ? 1 : 0
  endpoint_type             = "PUBLIC"
  identity_provider_type    = "SERVICE_MANAGED"
  security_policy_name      = "TransferSecurityPolicy-SshAuditCompliant-2025-02"
  logging_role           = aws_iam_role.transfer_logging.arn

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

