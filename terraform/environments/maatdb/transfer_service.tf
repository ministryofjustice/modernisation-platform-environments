# AWS Transfer Service

locals {

  transfer_secret_json_list = local.build_transfer ? try(jsondecode(data.aws_secretsmanager_secret_version.transfer_service_secret_version[0].secret_string), []) : []

  ingress_cidrs = [
    for obj in local.transfer_secret_json_list : obj.value
    if obj.type == "ingress_cidr"
  ]

  username = try(
    [for obj in local.transfer_secret_json_list : obj.value if obj.type == "username"][0],
    ""
  )

  user_public_key = try(
    [for obj in local.transfer_secret_json_list : obj.value if obj.type == "public_key"][0],
    ""
  )

  user_folder = try(
    [for obj in local.transfer_secret_json_list : obj.value if obj.type == "folder"][0],
    ""
  )

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
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_bucket["inbound"].bucket.arn,
          "${module.s3_bucket["inbound"].bucket.arn}/${local.user_folder}"
        ]
      },
      {
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
  })
}

resource "aws_security_group" "transfer_server_sg" {
  count = local.build_transfer ? 1 : 0
  name        = "transfer-server-sg"
  description = "xhibit transfer service security group"
  vpc_id      =  data.aws_vpc.shared.id 

  ingress {
    description = "SSH ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.ingress_cidrs
  }
}

resource "aws_eip" "transfer_eip_set" {
  count = 3
  domain = "vpc"
}

resource "aws_transfer_server" "transfer_service_server" {
  count = local.build_transfer ? 1 : 0
  endpoint_type               = "VPC"
  identity_provider_type      = "SERVICE_MANAGED"
  security_policy_name        = "TransferSecurityPolicy-SshAuditCompliant-2025-02"
  endpoint_details {
    vpc_id                 = data.aws_vpc.shared.id
    subnet_ids             = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
    address_allocation_ids = aws_eip.transfer_eip_set[*].id
    security_group_ids     = [aws_security_group.transfer_server_sg[0].id]
  }
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-xhibit-transfer-service"
    }
  )
}

resource "aws_transfer_user" "transfer_user" {
  count         = local.build_transfer ? 1 : 0
  server_id     = aws_transfer_server.transfer_service_server[0].id
  user_name     = local.username
  role          = aws_iam_role.transfer_role[0].arn
  home_directory = local.user_folder

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-xhibit-inbound-user"
    }
  )
}

resource "aws_transfer_ssh_key" "transfer_user_key" {
  count     = local.build_transfer ? 1 : 0
  server_id = aws_transfer_server.transfer_service_server[0].id
  user_name = aws_transfer_user.transfer_user[0].user_name
  body      = local.user_public_key
}
