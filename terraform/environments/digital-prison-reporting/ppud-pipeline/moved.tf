# These resources/modules gained a `count` argument (to skip creation in test).
# The moved blocks preserve existing state so non-test environments are not destroyed/recreated.
# Can be removed once state is moved.

moved {
  from = module.ppud_replication_destination
  to   = module.ppud_replication_destination[0]
}

moved {
  from = module.ppud_kms
  to   = module.ppud_kms[0]
}

moved {
  from = module.ppud_rds_export
  to   = module.ppud_rds_export[0]
}

moved {
  from = module.ppud_rds_export_secret
  to   = module.ppud_rds_export_secret[0]
}

moved {
  from = module.ppud_slack_webhook
  to   = module.ppud_slack_webhook[0]
}

moved {
  from = module.ppud_copy_object
  to   = module.ppud_copy_object[0]
}

moved {
  from = module.check_recent_file
  to   = module.check_recent_file[0]
}

moved {
  from = aws_security_group.ppud_db
  to   = aws_security_group.ppud_db[0]
}

moved {
  from = aws_vpc_security_group_ingress_rule.ppud_db_ingress
  to   = aws_vpc_security_group_ingress_rule.ppud_db_ingress[0]
}

moved {
  from = aws_sns_topic_subscription.sfn_events
  to   = aws_sns_topic_subscription.sfn_events[0]
}

moved {
  from = aws_lambda_permission.ppud_allow_bucket
  to   = aws_lambda_permission.ppud_allow_bucket[0]
}

moved {
  from = aws_s3_bucket_notification.ppud_land_bucket
  to   = aws_s3_bucket_notification.ppud_land_bucket[0]
}

moved {
  from = aws_lambda_permission.allow_eventbridge_check_recent_file
  to   = aws_lambda_permission.allow_eventbridge_check_recent_file[0]
}

moved {
  from = aws_cloudwatch_event_rule.check_recent_file_daily
  to   = aws_cloudwatch_event_rule.check_recent_file_daily[0]
}

moved {
  from = aws_cloudwatch_event_target.check_recent_file_daily
  to   = aws_cloudwatch_event_target.check_recent_file_daily[0]
}
