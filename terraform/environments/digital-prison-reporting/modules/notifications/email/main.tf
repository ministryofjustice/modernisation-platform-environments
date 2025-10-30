resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = var.sns_topic_arn
  protocol  = "email"
  endpoint  = var.email_url

   lifecycle {
    ignore_changes = [tags]
  }
}