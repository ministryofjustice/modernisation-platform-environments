# Trust relationship that allows an account to assume this role. The account is passed in as a variable.
# The external client does not receive permanent credentials for this role. 
# Instead, a principal in their account calls STS AssumeRole and receives temporary credentials.

# change to allow it to access multiple buckets, keys and glue tables.

resource "aws_iam_role" "this" {
  name                 = var.role_name
  max_session_duration = var.max_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowTrustedAccount"
        Effect = "Allow"
        # This allows any principal in the trusted account to assume the role. 
        # If we want to restrict this further, we can specify a specific IAM user or role ARN instead of using the root ARN.
        # Principal = {
        # AWS = var.trusted_role_arn
        # }
        Principal = {
          AWS = "arn:aws:iam::${var.trusted_account_id}:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# Creates inline IAM policy for the role, giving permissions to the assuming account.
resource "aws_iam_role_policy" "this" {
  name = "${var.role_name}-policy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      # Listing is bucket level so it's split out from the other S3 permissions which are object level.
      {
        Sid      = "ListBucketPrefix"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = var.bucket_arn

        Condition = {
          StringLike = {
            "s3:prefix" = [
              var.s3_prefix,
              "${var.s3_prefix}/*"
            ]
          }
        }
      },

      # Object level permissions.
      {
        Sid      = "ManageS3Objects"
        Effect   = "Allow"
        Action   = var.s3_object_actions
        Resource = "${var.bucket_arn}/${var.s3_prefix}/*"
      },

      {
        Sid      = "UseKmsKey"
        Effect   = "Allow"
        Action   = var.kms_actions
        Resource = var.kms_key_arn
      },

      {
        Sid    = "ManageGlueTables"
        Effect = "Allow"
        Action = var.glue_actions

        Resource = [
          var.glue_catalog_arn,
          var.glue_database_arn,
          local.glue_table_arn
        ]
      },

      {
        Sid      = "AllowAssumeRole"
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = aws_iam_role.this.arn
      }
    ]
  })
}


