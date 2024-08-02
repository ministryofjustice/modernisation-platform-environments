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

# Create a Role to Allow any Audit Clients of this environment, or any Repository
# for this environment to write to the DMS S3 bucket
resource "aws_iam_role" "dms_s3_writer_role" {
 count = length(local.dms_s3_writer_account_ids) > 0 ? 1 : 0
  name = local.dms_s3_writer_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for principal in local.dms_s3_writer_account_ids:
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${principal}:root",
          service = "dms.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy_document" "dms_s3_writer_policy_data"  {
 statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [ "arn:aws:s3:::${module.s3_bucket_dms_destination.bucket.bucket}" ]
  }
}

resource "aws_iam_policy" "dms_s3_writer_policy" {
  count       = length(local.dms_s3_writer_account_ids) > 0 ? 1 : 0
  name        = "dms-s3-writer-policy"
  description = "Policy to allow audit clients and repository putting data to the DMS S3 bucket"
  policy      = data.aws_iam_policy_document.dms_s3_writer_policy_data.json
}

resource "aws_iam_role_policy_attachment" "dms_s3_writer_policy_attachment" {
  count      = length(local.dms_s3_writer_account_ids) > 0 ? 1 : 0
  role       = aws_iam_role.dms_s3_writer_role[0].name
  policy_arn = aws_iam_policy.dms_s3_writer_policy[0].arn
}