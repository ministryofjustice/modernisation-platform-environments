resource "aws_sns_topic" "ses_notifications" {
  name = "ses-bounce-complaint-topic"
}