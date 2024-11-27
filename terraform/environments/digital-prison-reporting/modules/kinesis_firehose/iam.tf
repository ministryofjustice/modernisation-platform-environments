resource "aws_iam_role" "firehose_role" {
  name = var.name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

## Kines Data Stream Developer Policy
resource "aws_iam_policy" "firehose-add-policy" {
  name        = var.name
  description = "Kinesis Firehose Stream Policy"
  path        = "/"

  policy = data.aws_iam_policy_document.firehose-policy.json
}

## Firehose additional Policy
data "aws_iam_policy_document" "firehose-policy" {
  #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions. TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  statement {
    actions = [
      "kms:*",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${var.target_s3_id}",
      "arn:aws:s3:::${var.target_s3_id}/*"
    ]
  }

  statement {
    actions = [
      "kinesis:DescribeStream",
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards",
    ]
    resources = [
      "arn:aws:kinesis:${var.aws_region}:${var.aws_account_id}:stream/${var.kinesis_source_stream_name}"
    ]
  }

  statement {
    actions = [
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions"
    ]
    resources = [
      "arn:aws:glue:${var.aws_region}:${var.aws_account_id}:*"
    ]
  }

  statement {
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:/aws/kinesisfirehose/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "firehose-extra-policy" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose-add-policy.arn
}