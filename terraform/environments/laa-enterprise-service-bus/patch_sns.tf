######################################
### SNS Topic for Priority P1 Messages
######################################

resource "aws_sns_topic" "patch_priority_p1" {
  count                            = local.environment == "test" ? 1 : 0
  name                             = "PATCH-Priority-P1.fifo"
  fifo_topic                       = true
  content_based_deduplication      = true
  sqs_success_feedback_role_arn    = aws_iam_role.sns_feedback.arn
  sqs_success_feedback_sample_rate = 100
  sqs_failure_feedback_role_arn    = aws_iam_role.sns_feedback.arn
  kms_master_key_id                = "alias/aws/sns"

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-patch-sns-priority-p1-topic"
    }
  )
}

###########################################
### SNS Topic for Provider Banks Messages
###########################################

resource "aws_sns_topic" "patch_provider_banks" {
  count                            = local.environment == "test" ? 1 : 0
  name                             = "PATCH-Provider-Banks-P1.fifo"
  fifo_topic                       = true
  content_based_deduplication      = true
  sqs_success_feedback_role_arn    = aws_iam_role.sns_feedback.arn
  sqs_success_feedback_sample_rate = 100
  sqs_failure_feedback_role_arn    = aws_iam_role.sns_feedback.arn
  kms_master_key_id                = "alias/aws/sns"

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-patch-sns-provider-banks-topic"
    }
  )
}

###############################################
### Subscribe SQS Provider queues to SNS Topic
###############################################

resource "aws_sns_topic_subscription" "patch_ccms_provider" {
  count     = local.environment == "test" ? 1 : 0
  topic_arn = aws_sns_topic.patch_provider_banks[0].arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.patch_ccms_provider_q[0].arn
}
