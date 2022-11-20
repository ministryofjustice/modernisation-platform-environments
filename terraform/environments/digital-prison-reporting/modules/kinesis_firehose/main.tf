resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "terraform-kinesis-firehose-extended-s3-test-stream"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = var.kinesis_source_stream_arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn       = aws_iam_role.firehose_role.arn
    bucket_arn     = var.source_s3_arn
    kms_key_arn    = var.source_s3_kms
    s3_backup_mode = "Disabled"

    cloudwatch_logging_options {
      enabled         = var.cloudwatch_logging_enabled
      log_group_name  = length(var.cloudwatch_log_group_name) > 0 ? var.cloudwatch_log_group_name : format("/aws/kinesisfirehose/%s", var.name)
      log_stream_name = var.cloudwatch_log_stream_name
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_role"

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

  inline_policy = {
    name = "kinesis-s3-inline-policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ],
          Resource = [
            "arn:aws:s3:::${var.source_s3_id}",
            "arn:aws:s3:::${var.source_s3_id}/*"
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "kinesis:DescribeStream",
            "kinesis:GetShardIterator",
            "kinesis:GetRecords",
            "kinesis:ListShards"
          ],
          Resource = "arn:aws:kinesis:${var.aws_region}:${var.aws_account_id}:stream/${var.kinesis_source_stream_name}"
        },
        {
          Effect = "Allow",
          Action = [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          Resource = [
            "*"
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "logs:PutLogEvents"
          ],
          Resource = [
            "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:/aws/kinesisfirehose/*"
          ]
        }
      ]
    })
  }
}