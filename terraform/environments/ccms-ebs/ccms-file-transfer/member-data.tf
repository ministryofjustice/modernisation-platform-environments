data "aws_sns_topic" "s3_topic" {
  name = "s3-event-notification-topic"
}