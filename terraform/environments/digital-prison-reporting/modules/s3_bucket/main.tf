#------------------------------------------------------------------------------
# S3 Bucket for DPR Application IAAC
#------------------------------------------------------------------------------
#tfsec:ignore:AWS002 tfsec:ignore:AWS098
resource "aws_s3_bucket" "application_tf_state" { # TBC "application_tf_state" should be generic
  count = var.create_s3 ? 1 : 0

  #checkov:skip=CKV_AWS_18
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV2_AWS_6
  bucket = var.name

  lifecycle {
    prevent_destroy = false
  }

  tags = var.tags
}

resource "aws_s3_bucket_acl" "application_tf_state" { # TBC "application_tf_state" should be generic
  bucket = aws_s3_bucket.application_tf_state[0].id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.application_tf_state[0].id
  rule {
    id     = var.name
    status = "Enabled"

    noncurrent_version_transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = 365
      storage_class = "GLACIER"
    }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "application_tf_state" {
  bucket = aws_s3_bucket.application_tf_state[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.custom_kms_key
    }
  }
}

resource "aws_sqs_queue_policy" "allow_sqs_access" {
  count = var.create_notification_queue ? 1 : 0

  queue_url = aws_sqs_queue.notification_queue[0].id
  policy    = data.aws_iam_policy_document.allow_sqs_access[0].json
}

data "aws_iam_policy_document" "allow_sqs_access" {
  count = var.create_notification_queue ? 1 : 0
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["SQS:SendMessage"]

    resources = [aws_sqs_queue.notification_queue[0].arn]
  }
}

resource "aws_sqs_queue" "notification_queue" {
  count = var.create_notification_queue ? 1 : 0

  name                      = var.s3_notification_name
  message_retention_seconds = var.sqs_msg_retention_seconds
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.create_notification_queue ? 1 : 0
  bucket = aws_s3_bucket.application_tf_state[0].id

  queue {
    queue_arn     = aws_sqs_queue.notification_queue[0].arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.filter_prefix
  }
}

#resource "aws_s3_bucket_versioning" "application_tf_state" {
#  bucket = aws_s3_bucket.application_tf_state.id
#  versioning_configuration {
#    status = "Disabled"
#  }
#}

#S3 bucket access policy
#resource "aws_iam_policy" "application_tf_state_policy" {
#  name   = "${local.project}-terraform-state-s3-policy"
#  policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Action": [
#        "kms:DescribeKey",
#        "kms:GenerateDataKey",
#        "kms:Encrypt",
#        "kms:Decrypt"
#      ],
#      "Resource": "${aws_kms_key.s3.arn}"
#    },
#    {
#      "Effect": "Allow",
#      "Action": [
#        "s3:ListBucket",
#        "s3:GetBucketLocation"
#      ],
#      "Resource": [
#          "${aws_s3_bucket.application_tf_state.arn}"
#      ]
#    },
#    {
#      "Effect": "Allow",
#      "Action": [
#        "s3:GetObjectMetaData",
#        "s3:GetObject",
#        "s3:PutObject",
#        "s3:ListMultipartUploadParts",
#        "s3:AbortMultipartUpload"
#      ],
#      "Resource": [
#        "${aws_s3_bucket.application_tf_state.arn}/*"
#      ]
#    }
#  ]
#}
#EOF
#}

#resource "aws_iam_role" "application_tf_state_role" {
#  name               = "${local.project}-terraform-state-s3-role"
#  assume_role_policy = data.aws_iam_policy_document.s3-access-policy.json
#  tags = merge(
#    local.tags,
#    {
#      Name = "${local.project}-terraform-state-s3-role"
#    }
#  )
#}

#resource "aws_iam_role_policy_attachment" "application_tf_state_attachment" {
#  role       = aws_iam_role.application_tf_state_role.name
#  policy_arn = aws_iam_policy.application_tf_state_policy.arn
#}

#data "aws_iam_policy_document" "s3-access-policy" {
#  version = "2012-10-17"
#  statement {
#    sid    = ""
#    effect = "Allow"
#    actions = [
#      "sts:AssumeRole",
#    ]
#    principals {
#      type = "Service"
#      identifiers = [
#        "rds.amazonaws.com",
#        "ec2.amazonaws.com",
#      ]
#    }
#  }
#}