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

# The following role, dms_s3_writer_role, allows the DMS service to write to the local S3 DMS bucket 
# This is to allow data within the Delius database to be staged to flat files on S3.
resource "aws_iam_role" "dms_s3_writer_role" {
  name = local.dms_s3_writer_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "dms_s3_bucket_writer_policy" {
  count = length(keys(local.bucket_map)) > 0 ? 1 : 0
  name  = "${local.dms_s3_writer_role_name}-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:PutObjectTagging"
        ]
        Resource = concat([for bucket in values(local.bucket_map) : "arn:aws:s3:::${bucket}/*"], ["${module.s3_bucket_dms_destination.bucket.arn}/*"])
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = concat([for bucket in values(local.bucket_map) : "arn:aws:s3:::${bucket}"], [module.s3_bucket_dms_destination.bucket.arn])
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_s3_bucket_writer_policy_attachment" {
  count      = length(keys(local.bucket_map)) > 0 ? 1 : 0
  role       = aws_iam_role.dms_s3_writer_role.name
  policy_arn = aws_iam_policy.dms_s3_bucket_writer_policy[0].arn
}


# The following role is used to allow the DMS service to read from the S3 Staging Bucket,
# And also to allow the name of the Repository Bucket to be found by the Client Account.
resource "aws_iam_role" "dms_s3_reader_role" {
  name = local.dms_s3_reader_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# The reader role only provides access to the local bucket, not those in other accounts
resource "aws_iam_policy" "dms_s3_bucket_reader_policy" {
  name = "${local.dms_s3_reader_role_name}-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = ["${module.s3_bucket_dms_destination.bucket.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [module.s3_bucket_dms_destination.bucket.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_s3_bucket_reader_policy_attachment" {
  role       = aws_iam_role.dms_s3_reader_role.name
  policy_arn = aws_iam_policy.dms_s3_bucket_reader_policy.arn
}