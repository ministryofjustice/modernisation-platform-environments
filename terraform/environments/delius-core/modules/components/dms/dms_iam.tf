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
    count  = length(keys(local.dms_s3_cross_account_bucket_arns)) > 0 ? 1 : 0
    name   = "dms-s3-bucket-writer-policy"
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
        Effect    = "Allow"
        Action    = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:PutObjectTagging"         
        ]
        Resource = [for bucket in values(local.dms_s3_cross_account_bucket_arns) : "${bucket}/*"]
        },
        {
        Effect    = "Allow"
        Action    = [
          "s3:ListBucket"
        ]
        Resource = [for bucket in values(local.dms_s3_cross_account_bucket_arns) : bucket]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_s3_bucket_writer_policy_attachment" {
  count      = length(keys(local.dms_s3_cross_account_bucket_arns)) > 0 ? 1 : 0
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
      {
        Effect = "Allow"
        Principals = {
            type        = "AWS"
            identifiers = "arn:aws:iam::${var.platform_vars.environment_management.account_ids["delius-core-${var.dms_config.audit_target_endpoint.write_environment}"]}"
          }
        Action = "sts:AssumeRole"
      }
    ]
  })
}



# The reader role only provides access to the local bucket, not those in other accounts
resource "aws_iam_policy" "dms_s3_bucket_reader_policy" {
    name   = "dms-s3-bucket-reader-policy"
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
        Effect    = "Allow"
        Action    = [
          "s3:GetObject"
        ]
        Resource = ["${module.s3_bucket_dms_destination.bucket.arn}/*"]
        },
        {
        Effect    = "Allow"
        Action    = [
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


