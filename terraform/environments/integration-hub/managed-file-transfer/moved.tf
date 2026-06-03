moved {
  from = module.lambda_clean_file_presigned_url_notifier
  to   = module.proof_of_concept_notification.module.lambda_clean_file_presigned_url_notifier
}

moved {
  from = module.sqs_clean_file_notifications
  to   = module.proof_of_concept_notification.module.sqs_clean_file_notifications
}

moved {
  from = module.chatbot_clean_file_download_notifications
  to   = module.proof_of_concept_notification.module.chatbot_clean_file_download_notifications
}

moved {
  from = aws_sns_topic.clean_bucket_events
  to   = module.proof_of_concept_notification.aws_sns_topic.clean_bucket_events
}

moved {
  from = aws_sns_topic_policy.clean_bucket_events
  to   = module.proof_of_concept_notification.aws_sns_topic_policy.clean_bucket_events
}

moved {
  from = aws_s3_bucket_notification.clean_bucket_events
  to   = module.proof_of_concept_notification.aws_s3_bucket_notification.clean_bucket_events
}

moved {
  from = aws_sns_topic_subscription.clean_bucket_events_to_sqs
  to   = module.proof_of_concept_notification.aws_sns_topic_subscription.clean_bucket_events_to_sqs
}

moved {
  from = aws_sns_topic.clean_file_download_notifications
  to   = module.proof_of_concept_notification.aws_sns_topic.clean_file_download_notifications
}

moved {
  from = aws_sns_topic_policy.clean_file_download_notifications
  to   = module.proof_of_concept_notification.aws_sns_topic_policy.clean_file_download_notifications
}
