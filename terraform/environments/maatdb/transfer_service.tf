# AWS Transfer Service

locals {

  decoded_transfer_service_secret = try(
    jsondecode(
      length(data.aws_secretsmanager_secret_version.transfer_service_secret_version) > 0 ?
      data.aws_secretsmanager_secret_version.transfer_service_secret_version[0].secret_string :
      "{}"
    ),
    []
  )

  transfer_service_details = {
    for pair in local.decoded_transfer_service_secret :
    "${pair.name}.${pair.type}" => pair.value
    if contains(keys(pair), "name") && contains(keys(pair), "type") && contains(keys(pair), "value")
  }


  transfer_service = {
    job_name      = "xhibit-inbound"
    bucket_name   = try(module.s3_bucket.inbound.bucket.bucket, "")
    bucket_folder = "temp/"
  }

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
          "${module.s3_bucket["inbound"].bucket.arn}/*"
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
