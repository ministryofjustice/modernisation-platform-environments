
#  bucket notification for data store
resource "aws_s3_bucket_notification" "historic_data_store" {
  depends_on = [aws_sns_topic_policy.historic_s3_events_policy]
  bucket     = module.s3-data-bucket.bucket.id

  # Only for copy events as those are events triggered by data being copied
  #  from landing bucket.
  topic {
    topic_arn = aws_sns_topic.historic_s3_events.arn
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_suffix = ".bak"
  }
  topic {
    topic_arn = aws_sns_topic.historic_s3_events.arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".zip"
  }
  topic {
    topic_arn = aws_sns_topic.historic_s3_events.arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".bacpac"
  }
}

# sns topic to allow multiple lambdas to be triggered off of it
resource "aws_sns_topic" "historic_s3_events" {
  name              = "${module.s3-data-bucket.bucket.id}-historic-object-created-topic"
  kms_master_key_id = "alias/aws/sns"
}

# IAM policy document for the SNS topic policy
data "aws_iam_policy_document" "historic_sns_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.historic_s3_events.arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [module.s3-data-bucket.bucket.arn]
    }
  }
}

# Apply policy to the SNS topic
resource "aws_sns_topic_policy" "historic_s3_events_policy" {
  arn    = aws_sns_topic.historic_s3_events.arn
  policy = data.aws_iam_policy_document.historic_sns_policy.json
}

# -----------------------------------------------
# Live data sns notification
# -----------------------------------------------


#  bucket notification for data store
resource "aws_s3_bucket_notification" "live_serco_fms_data_store" {
  depends_on = [aws_sns_topic_policy.live_serco_fms_s3_events_policy]
  bucket     = module.s3-data-bucket.bucket.id

  # Only for copy events as those are events triggered by data being copied
  #  from landing bucket.
  topic {
    topic_arn = aws_sns_topic.live_serco_fms_s3_events.arn
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_suffix = ".JSON"
  }
}

# sns topic to allow multiple lambdas to be triggered off of it
resource "aws_sns_topic" "live_serco_fms_s3_events" {
  name              = "${module.s3-data-bucket.bucket.id}-live-object-created-topic"
  kms_master_key_id = "alias/aws/sns"
}

# IAM policy document for the SNS topic policy
data "aws_iam_policy_document" "live_serco_fms_sns_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.live_serco_fms_s3_events.arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [module.s3-data-bucket.bucket.arn]
    }
  }
}

# Apply policy to the SNS topic
resource "aws_sns_topic_policy" "live_serco_fms_s3_events_policy" {
  arn    = aws_sns_topic.live_serco_fms_s3_events.arn
  policy = data.aws_iam_policy_document.live_serco_fms_sns_policy.json
}
