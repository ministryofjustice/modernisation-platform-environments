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
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "arn:aws:s3:::${var.env_name}-dms-destination-bucket*",
      "arn:aws:s3:::${var.env_name}-dms-destination-bucket*/*"
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
