locals {
  bucket_arn   = "arn:aws:s3:::${var.bucket_name}"
  prefix       = trim(var.prefix, "/")
  location_arn = local.prefix == "" ? local.bucket_arn : "${local.bucket_arn}/${local.prefix}"
}

resource "aws_iam_role" "lakeformation_s3_access_role" {
  name = var.role_name
  tags = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lakeformation.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lakeformation_s3_access_policy" {
  name = "lakeformation-s3-access-policy"
  role = aws_iam_role.lakeformation_s3_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      merge({
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [local.bucket_arn]
        }, local.prefix == "" ? {} : {
        Condition = {
          StringLike = {
            "s3:prefix" = [local.prefix, "${local.prefix}/", "${local.prefix}/*"]
          }
        }
      }),
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${local.location_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey*", "kms:DescribeKey"]
        Resource = [var.kms_key_arn]
      }
    ]
  })
}

resource "aws_lakeformation_resource" "s3_location" {
  role_arn   = aws_iam_role.lakeformation_s3_access_role.arn
  arn        = local.location_arn
  depends_on = [aws_iam_role_policy.lakeformation_s3_access_policy]
}