output "aws_secretsmanager_secret_support_email_account_arn" {
  description = "aws_secretsmanager_secret support_email_account arn"
  value       = aws_secretsmanager_secret.support_email_account.arn
}

#

output "aws_secretsmanager_secret_version_support_email_account_arn" {
  description = "aws_secretsmanager_secret_version support_email_account arn"
  value       = aws_secretsmanager_secret_version.support_email_account.arn
}

output "aws_secretsmanager_secret_version_support_email_account_id" {
  description = "aws_secretsmanager_secret_version support_email_account id"
  value       = aws_secretsmanager_secret_version.support_email_account.id
}

#

output "aws_sns_topic_cw_alerts_arn" {
  description = "aws_sns_topic cw_alerts arn"
  value       = aws_sns_topic.cw_alerts.arn
}

#

output "aws_sns_topic_subscription_cw_subscription_arn" {
  description = "aws_sns_topic_subscription cw_subscription arn"
  value       = aws_sns_topic_subscription.cw_subscription.arn
}

output "aws_sns_topic_subscription_cw_subscription_owner_id" {
  description = "aws_sns_topic_subscription cw_subscription owner_id"
  value       = aws_sns_topic_subscription.cw_subscription.owner_id
}

#

output "aws_sns_topic_s3_topic_arn" {
  description = "aws_sns_topic s3_topic"
  value       = aws_sns_topic.s3_topic
}

#

output "aws_sns_topic_subscription_s3_subscription_arn" {
  description = "aws_sns_topic_subscription s3_subscription arn"
  value       = aws_sns_topic_subscription.s3_subscription.arn
}

output "aws_sns_topic_subscription_s3_subscription_owner_id" {
  description = "aws_sns_topic_subscription s3_subscription owner_id"
  value       = aws_sns_topic_subscription.s3_subscription.owner_id
}

#

output "aws_sns_topic_ddos_alarm_arn" {
  description = "aws_sns_topic ddos_alarm arn"
  value       = aws_sns_topic.ddos_alarm.arn
}

#

output "aws_sns_topic_subscription_ddos_subscription_arn" {
  description = "aws_sns_topic_subscription ddos_subscription arn"
  value       = aws_sns_topic_subscription.ddos_subscription.arn
}

output "aws_sns_topic_subscription_ddos_subscription_owner_id" {
  description = "aws_sns_topic_subscription ddos_subscription owner_id"
  value       = aws_sns_topic_subscription.ddos_subscription.owner_id
}
