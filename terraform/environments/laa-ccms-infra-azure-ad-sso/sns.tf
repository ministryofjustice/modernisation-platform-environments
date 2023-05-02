resource "aws_sns_topic" "cw_alerts" {
  name = "laa-ccms-ebs-vision-ec2-alerts"
}

resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.cw_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}


#### S3 ####
resource "aws_sns_topic" "s3_topic" {
  name   = "s3-event-notification-topic"
  policy = data.aws_iam_policy_document.s3_topic_policy.json
}
resource "aws_sns_topic_policy" "s3_policy" {
  arn    = aws_sns_topic.s3_topic.arn
  policy = data.aws_iam_policy_document.s3_topic_policy.json
}
