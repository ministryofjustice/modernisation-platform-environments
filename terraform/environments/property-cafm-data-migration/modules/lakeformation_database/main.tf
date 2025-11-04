data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

# Role for the lakeformation location resource
data "aws_iam_policy_document" "lakeformation_location_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lakeformation.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lakeformation_location_role" {
  name               = "${var.database_name}-location"
  assume_role_policy = data.aws_iam_policy_document.lakeformation_location_assume_role.json
}

# Policy to allow Lake Formation to access the S3 bucket
data "aws_iam_policy_document" "lakeformation_location_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.location_bucket}/${var.location_prefix}*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.location_bucket}"
    ]
  }

  # KMS permissions for encrypted S3 objects
  dynamic "statement" {
    for_each = var.kms_key_id != null ? [1] : []
    content {
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey",
        "kms:CreateGrant"
      ]
      resources = [var.kms_key_id]
    }
  }
}

resource "aws_iam_role_policy" "lakeformation_location_policy" {
  name   = "${var.database_name}-location-policy"
  role   = aws_iam_role.lakeformation_location_role.id
  policy = data.aws_iam_policy_document.lakeformation_location_policy.json
}

# S3 Data Source to ensure the bucket exists
data "aws_s3_bucket" "location_bucket" {
  count  = var.validate_location ? 1 : 0
  bucket = var.location_bucket
}

# Will appear in AWS Console under Lake Formation > Data Lake Locations
resource "aws_lakeformation_resource" "lakeformation_location" {
  arn                   = "arn:aws:s3:::${var.location_bucket}/${var.location_prefix}"
  role_arn              = aws_iam_role.lakeformation_location_role.arn
  hybrid_access_enabled = var.hybrid_access_enabled
}

resource "aws_glue_catalog_database" "lakeformation_database" {
  name         = var.database_name
  location_uri = "s3://${var.location_bucket}/${var.location_prefix}"
}
