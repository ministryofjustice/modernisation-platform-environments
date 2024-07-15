data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-cloudwatch-logs-role"
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
}

resource "aws_iam_role" "dms-vpc-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-vpc-role"
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role.name
}

# Allow client accounts to assume this role in the this account when it is the repository
resource "aws_iam_role" "dms_client_bucket_role" {
  count = length(var.dms_config.client_account_arns) > 0 ? 1 : 0
  name = "dms-client-buckets-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for principal in var.dms_config.client_account_arns:
      {
        Effect = "Allow",
        Principal = {
          AWS = principal
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy_document" "dms_s3_buckets_policy" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::*",
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.env_name}-dms-destination-bucket*"]
    }
  }

 statement {
    actions = [
      "s3:GetBucketAcl",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "arn:aws:s3:::${local.dms_s3_local_bucket_prefix}*",
      "arn:aws:s3:::${local.dms_s3_local_bucket_prefix}*/*"
    ]
  }

}

resource "aws_iam_policy" "dms_s3_buckets_policy" {
  count       = length(var.dms_config.client_account_arns) > 0 ? 1 : 0
  name        = "dms_s3_buckets_policy"
  description = "Policy to allow listing and writing S3 buckets with DMS destination prefix"
  policy      = data.aws_iam_policy_document.dms_s3_buckets_policy.json
}

resource "aws_iam_role_policy_attachment" "dms_s3_buckets_policy_attachment" {
  count      = length(var.dms_config.client_account_arns) > 0 ? 1 : 0
  role       = aws_iam_role.dms_client_bucket_role[0].name
  policy_arn = aws_iam_policy.dms_s3_buckets_policy[0].arn
}

resource "aws_iam_policy" "dms_s3_audit_target_policy" {
  count       = local.dms_s3_repository_bucket.prefix == null ? 0 : 1
  name        = "dms-s3-target-policy"
  description = "Policy to allow DMS to write Audit data to the repository S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.dms_s3_repository_bucket.prefix}*",
          "arn:aws:s3:::${local.dms_s3_repository_bucket.prefix}*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_s3_audit_target_policy_attachment" {
  count      = local.dms_s3_repository_bucket.prefix == null ? 0 : 1
  role       = aws_iam_role.dms-vpc-role.name
  policy_arn = aws_iam_policy.dms_s3_audit_target_policy[0].arn
}


# and allow this account to assume the role in the respective repository account when it is the cient
resource "aws_iam_policy" "dms_s3_assume_bucket_role_in_respository" {
   count       = local.dms_s3_repository_bucket.account_id == null ? 0 : 1
   name        = "dms-s3-assume-bucket-role-in-repository"
   description = "Policy to allow DMS to assume the dms-client-bucket-role in the repository account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource =  "arn:aws:iam::${local.dms_s3_repository_bucket.account_id}:role/dms-client-buckets-role",
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "dms_s3_assume_bucket_role_in_respository_attachment" {
  count       = local.dms_s3_repository_bucket.account_id == null ? 0 : 1
  role       = aws_iam_role.dms-vpc-role.name
  policy_arn = aws_iam_policy.dms_s3_assume_bucket_role_in_respository[0].arn
}

resource "aws_iam_role_policy_attachment" "dms_s3_assume_bucket_role_in_respository_attachment_for_debug" {
  count       = local.delius_account_id ==  326912278139 ? 1 : 0
  role       = "AWSReservedSSO_modernisation-platform-developer_4d411ef0fd3a5613"
  policy_arn = aws_iam_policy.dms_s3_assume_bucket_role_in_respository[0].arn
}
