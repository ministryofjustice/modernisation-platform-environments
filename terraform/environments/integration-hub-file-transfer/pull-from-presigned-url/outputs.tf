output "portal_url" { value = local.portal_url }
output "slack_notification_topics" {
  value = { for id, topic in module.sns_slack : id => topic.topic_arn }
}
